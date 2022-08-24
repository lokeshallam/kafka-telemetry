#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

BASIC_AUTH=""
if [[ $ENV == *_sasl ]]; then
  BASIC_AUTH="-u connect:connect-secret"
fi

# create acls for schema replicator connector
PRINCIPAL="schema"
TOPIC="_schemas_insecure"
GROUP="schema-replicator"
kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${PRINCIPAL}" \
--allow-host "*" --consumer --producer --topic $TOPIC --group $GROUP
[ $? -eq 1 ] && echo "Unable to create write ACL for topic \"$TOPIC\" and principal \"$PRINCIPAL\"" && exit

# verify conenct server is running and accepting requests
echo "curl -k $BASIC_AUTH --output /dev/null --silent --head --fail $KAFKA_CONNECT_URL/connectors"
printf "Waiting until connect server $KAFKA_CONNECT_URL is ready to accept requests"
until $(curl -k $BASIC_AUTH --output /dev/null --silent --head --fail $KAFKA_CONNECT_URL/connectors); do
    printf '.'
    sleep 3
done
echo ""
echo "Connect server $KAFKA_CONNECT_URL is ready to accept requests"

CONNECTOR="schemarepl"

if $SSL; then

KEYSTORE_LOCATION="$KEYSTORE_DIR/$PRINCIPAL.kafka_network.keystore.jks"
TRUSTSTORE_LOCATION="$KEYSTORE_DIR/$PRINCIPAL.kafka_network.truststore.jks"

if [[ $ENV == *_sasl ]]; then

#    "dest.kafka.bootstrap.servers": "loadbalancer:29092",
#    "dest.kafka.client.id": "$GROUP",
#    "dest.kafka.ssl.keystore.location": "$KEYSTORE_LOCATION",
#    "dest.kafka.ssl.keystore.password": "$KEYSTORE_PASSWORD",
#    "dest.kafka.ssl.truststore.location": "$TRUSTSTORE_LOCATION",
#    "dest.kafka.ssl.truststore.password": "$KEYSTORE_PASSWORD",
#    "dest.kafka.security.protocol": "SASL_SSL",
#    "dest.kafka.sasl.mechanism": "PLAIN",
#    "dest.kafka.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"$PRINCIPAL\" password=\"schema-secret\";",

POST_DATA=$(cat <<EOF
{
  "name": "$CONNECTOR",
  "config": {
    "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",
    "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "header.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
    "tasks.max": "1",
    "topic.whitelist": "$TOPIC",
    "schema.registry.topic": "$TOPIC",
    "src.kafka.bootstrap.servers": "loadbalancer:29092",
    "src.kafka.group.id": "$GROUP",
    "src.kafka.ssl.keystore.location": "$KEYSTORE_LOCATION",
    "src.kafka.ssl.keystore.password": "$KEYSTORE_PASSWORD",
    "src.kafka.ssl.truststore.location": "$TRUSTSTORE_LOCATION",
    "src.kafka.ssl.truststore.password": "$KEYSTORE_PASSWORD",
    "src.kafka.security.protocol": "SASL_SSL",
    "src.kafka.sasl.mechanism": "PLAIN",
    "src.kafka.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"$PRINCIPAL\" password=\"schema-secret\";",
    "schema.registry.url": "https://schema1:8081",
    "schema.registry.client.schema.registry.ssl.keystore.location": "$KEYSTORE_LOCATION",
    "schema.registry.client.schema.registry.ssl.keystore.password": "$KEYSTORE_PASSWORD",
    "schema.registry.client.schema.registry.ssl.truststore.location": "$TRUSTSTORE_LOCATION",
    "schema.registry.client.schema.registry.ssl.truststore.password": "$KEYSTORE_PASSWORD",
    "schema.registry.client.basic.auth.credentials.source": "USER_INFO",
    "schema.registry.client.basic.auth.user.info": "$PRINCIPAL:schema-secret"
  }
}
EOF
)

fi

fi

echo "Creating schema replicator connector"
curl -k $BASIC_AUTH --header "Content-Type: application/json" -X POST --data "$POST_DATA" $KAFKA_CONNECT_URL/connectors
echo "Created schema replicator connector"

sleep 10
echo "Checking status of schema replicator connector"
curl -k $BASIC_AUTH --header "Content-Type: application/json" $KAFKA_CONNECT_URL/connectors/$CONNECTOR/status