#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$2

[[ -z "$3" ]] && { echo "Partitions not specified" ; exit 1; }
PARTITIONS=$3

# create input topic for datagen connector
echo "Creating datagen connector topic \"$TOPIC\""
kafka-topics --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --create --topic ${TOPIC} --partitions ${PARTITIONS} --replication-factor 3
echo "Created datagen connector topic \"$TOPIC\""

PRINCIPAL="datagen"
CONNECTOR_NAME="$PRINCIPAL-$TOPIC"

# create RBAC role bindings for datagen connector if RBAC is enabled
if [[ $RBAC == "true" ]]; then

  echo "creating datagen role bindings"

  # login to cluster
  ../login.sh $ENV

  confluent iam rolebinding create --principal User:$PRINCIPAL --role DeveloperWrite --resource Topic:$TOPIC --cluster-name $KAFKA_CLUSTER

  SUBJECT="${TOPIC}-value"
  confluent iam rolebinding create --principal User:$PRINCIPAL --role DeveloperWrite --resource Subject:$SUBJECT --cluster-name $SCHEMA_CLUSTER

# create ACLs for datagen connector if RBAC not enabled
elif [[ $ACL == "true" ]]; then

  echo "creating datagen ACLs"

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${PRINCIPAL}" \
  --allow-host "*" --producer --topic $TOPIC
  [ $? -eq 1 ] && echo "Unable to create write ACL for topic \"$TOPIC\" and principal \"$PRINCIPAL\"" && exit

  sr-acl-cli --config $SCHEMA_CONFIG --add --principal $PRINCIPAL --operation SUBJECT_WRITE --subject $TOPIC-value

fi

# set basic auth username:secret if SASL enabled
BASIC_AUTH=""
if [[ $SASL == "true" ]]; then
  BASIC_AUTH="-u connect:connect-secret"
fi

# verify conenct server is running and accepting requests
echo "curl -k $BASIC_AUTH --output /dev/null --silent --head --fail $KAFKA_CONNECT_URL/connectors"
printf "Waiting until connect server $KAFKA_CONNECT_URL is ready to accept requests"
until $(curl -k $BASIC_AUTH --output /dev/null --silent --head --fail $KAFKA_CONNECT_URL/connectors); do
  printf '.'
  sleep 3
done
echo ""
echo "Connect server $KAFKA_CONNECT_URL is ready to accept requests"
 
if [[ $SSL == "true" ]]; then

  KEYSTORE_LOCATION="$KEYSTORE_DIR/$PRINCIPAL.$DOMAIN.keystore.jks"
  TRUSTSTORE_LOCATION="$KEYSTORE_DIR/$PRINCIPAL.$DOMAIN.truststore.jks"
  PASSWORD="datagen-secret"

  # SSL and SASL
  if [[ $SASL == "true" ]]; then

    SASL_MECHANISM=""
    JAAS_CONFIG=""
    KEYSTORE_SECRET=""
    USERNAME=""
    PASSWORD=""

    # SSL, SASL and RBAC
    if [[ $RBAC == "true" ]]; then

      SASL_MECHANISM="PLAIN"
      USERNAME="\${vault:secret/datagen:cp_username}"
      PASSWORD="\${vault:secret/datagen:cp_password}"
      JAAS_CONFIG="org.apache.kafka.common.security.plain.PlainLoginModule required username=\\\"\${vault:secret/datagen:cp_username}\\\" password=\\\"\${vault:secret/datagen:cp_password}\\\";"
      KEYSTORE_SECRET="\${secret:${CONNECTOR_NAME}:keypassword}"

      if [[ $ENV == "scram" ]]; then
        SASL_MECHANISM="SCRAM-SHA-512"
        JAAS_CONFIG="org.apache.kafka.common.security.scram.ScramLoginModule required username=\\\"\${vault:secret/datagen:cp_username}\\\" password=\\\"\${vault:secret/datagen:cp_password}\\\";"
      elif [[ $ENV == "gssapi" ]]; then
        SASL_MECHANISM="GSSAPI"
        JAAS_CONFIG="com.sun.security.auth.module.Krb5LoginModule required useKeyTab=true storeKey=true keyTab=\\\"/etc/security/keytabs/connect.keytab\\\" principal=\\\"\${vault:secret/datagen:cp_username}@${REALM}\\\";"
      fi

      echo "Creating datagen connector secrets"
      # create username secret
      echo "curl -k $BASIC_AUTH --header \"Content-Type: application/json\" -X POST --data \"{\"secret\": \"$PRINCIPAL\"}\" $KAFKA_CONNECT_URL/secret/paths/${CONNECTOR_NAME}/keys/username/versions"
      HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "{\"secret\": \"$PRINCIPAL\"}" --write-out "%{http_code}" \
      $KAFKA_CONNECT_URL/secret/paths/${CONNECTOR_NAME}/keys/username/versions)
      if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
        echo "Unable to create username secret for datagen connector" && exit
      fi

      # create password secret
      HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "{\"secret\": \"$PASSWORD\"}" --write-out "%{http_code}" \
      $KAFKA_CONNECT_URL/secret/paths/${CONNECTOR_NAME}/keys/password/versions)
      if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
        echo "Unable to create password secret for datagen connector" && exit
      fi

      # create keystore password secret
      HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "{\"secret\": \"$KEYSTORE_PASSWORD\"}" --write-out "%{http_code}" \
      $KAFKA_CONNECT_URL/secret/paths/${CONNECTOR_NAME}/keys/keypassword/versions)
      if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
        echo "Unable to create keystore password secret for datagen connector" && exit
      fi

    # SSL, SASL and ACLs (no connect secret registry)
    else

      USERNAME="$PRINCIPAL"
      PASSWORD="datagen-secret"
      SASL_MECHANISM="PLAIN"
      JAAS_CONFIG="org.apache.kafka.common.security.plain.PlainLoginModule required username=\\\"${USERNAME}\\\" password=\\\"${PASSWORD}\\\";"
      KEYSTORE_SECRET="$KEYSTORE_PASSWORD"

      if [[ $ENV == "scram" ]]; then
        SASL_MECHANISM="SCRAM-SHA-512"
        JAAS_CONFIG="org.apache.kafka.common.security.scram.ScramLoginModule required username=\\\"${USERNAME}\\\" password=\\\"${PASSWORD}\\\";"
      elif [[ $ENV == "gssapi" ]] || [[ $ENV == "gssapi_super" ]]; then
        SASL_MECHANISM="GSSAPI"
        JAAS_CONFIG="com.sun.security.auth.module.Krb5LoginModule required useKeyTab=true storeKey=true keyTab=\\\"/etc/security/keytabs/connect.keytab\\\" principal=\\\"${USERNAME}@${REALM}\\\";"
      fi

    fi

    # create datagen connector for SASL SSL env
    POST_DATA=$(cat <<EOF
{
  "name": "$CONNECTOR_NAME",
  "config": {
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "tasks.max": "1",
    "kafka.topic": "$TOPIC",
    "schema.filename": "/schemas/person.avsc",
    "schema.keyfield": "id",
    "key.converter": "org.apache.kafka.connect.converters.LongConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "$SCHEMA_URL",
    "value.converter.schema.registry.ssl.keystore.location": "$KEYSTORE_LOCATION",
    "value.converter.schema.registry.ssl.keystore.password": "$KEYSTORE_SECRET",
    "value.converter.schema.registry.ssl.key.password": "$KEYSTORE_SECRET",
    "value.converter.schema.registry.ssl.truststore.location": "$TRUSTSTORE_LOCATION",
    "value.converter.schema.registry.ssl.truststore.password": "$KEYSTORE_SECRET",
    "value.converter.schemas.enable": "true",
    "value.converter.schema.registry.basic.auth.user.info": "$USERNAME:$PASSWORD",
    "value.converter.schema.registry.basic.auth.credentials.source": "USER_INFO",
    "max.interval": "10",
    "iterations": "1000",
    "producer.override.sasl.mechanism": "$SASL_MECHANISM",
    "producer.override.sasl.jaas.config": "$JAAS_CONFIG"
  }
}
EOF
    )


  # Just SSL, No SASL
  else

    # create datagen connector for mTLS env
    POST_DATA=$(cat <<EOF
{
  "name": "$CONNECTOR_NAME",
  "config": {
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "tasks.max": "1",
    "kafka.topic": "$TOPIC",
    "schema.filename": "/schemas/person.avsc",
    "schema.keyfield": "id",
    "key.converter": "org.apache.kafka.connect.converters.LongConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "$SCHEMA_URL",
    "value.converter.schema.registry.ssl.keystore.location": "$KEYSTORE_LOCATION",
    "value.converter.schema.registry.ssl.keystore.password": "$KEYSTORE_PASSWORD",
    "value.converter.schema.registry.ssl.key.password": "$KEYSTORE_PASSWORD",
    "value.converter.schema.registry.ssl.truststore.location": "$TRUSTSTORE_LOCATION",
    "value.converter.schema.registry.ssl.truststore.password": "$KEYSTORE_PASSWORD",
    "value.converter.schemas.enable": "true",
    "value.converter.basic.auth.credentials.source": "USER_INFO",
    "value.converter.basic.auth.user.info": "$PRINCIPAL:$PASSWORD",
    "max.interval": "10",
    "iterations": "1000",
    "producer.override.security.protocol": "SSL",
    "producer.override.ssl.keystore.location": "$KEYSTORE_LOCATION",
    "producer.override.ssl.keystore.password": "$KEYSTORE_PASSWORD",
    "producer.override.ssl.key.password": "$KEYSTORE_PASSWORD",
    "producer.override.ssl.truststore.location": "$TRUSTSTORE_LOCATION",
    "producer.override.ssl.truststore.password": "$KEYSTORE_PASSWORD"
  }
}
EOF
    )

  fi

else

    # create datagen connector for open env
    POST_DATA=$(cat <<EOF
{
  "name": "$CONNECTOR_NAME",
  "config": {
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "tasks.max": "1",
    "kafka.topic": "$TOPIC",
    "schema.filename": "/schemas/person.avsc",
    "schema.keyfield": "id",
    "key.converter": "org.apache.kafka.connect.converters.LongConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "$SCHEMA_URL",
    "value.converter.schemas.enable": "true",
    "max.interval": "10",
    "iterations": "1000"
  }
}
EOF
    )

fi

echo ""
echo $POST_DATA
echo ""

echo ""
echo "Creating datagen connector"
HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "$POST_DATA" --write-out "%{http_code}" $KAFKA_CONNECT_URL/connectors)
if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
  echo "Unable to create datagen connector" && exit
fi
echo ""
echo "Created datagen connector"

sleep 10
echo ""
echo "Checking status of datagen connector"
HTTP_CODE=$(curl -k $BASIC_AUTH --header "Content-Type: application/json" --write-out "%{http_code}" $KAFKA_CONNECT_URL/connectors/$CONNECTOR_NAME/status)
if [[ ${HTTP_CODE} -lt 200 || ${HTTP_CODE} -gt 299 ]] ; then
  echo "Unable to check status datagen connector" && exit
fi