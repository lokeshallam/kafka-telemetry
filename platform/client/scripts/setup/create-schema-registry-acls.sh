#!/bin/bash

echo "Creating general ACLs for schema registry"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

SCHEMAS="3"
if [[ "$2" ]]; then
  SCHEMAS="$2"
fi

SCHEMA_GROUP="schema-registry"
SCHEMA_TOPIC="_schemas"
SCHEMA_ACL_TOPIC="_schemas_acl"
CONSUMER_OFFSETS_TOPIC="__consumer_offsets"
LICENSE_TOPIC="_confluent-license"

# get the kafka cluster ID
CLUSTER_ID=$(kafka-cluster cluster-id --bootstrap-server $BROKER_URL --config $KAFKA_CONFIG | sed -n "s/^Cluster ID: \(.*\)$/\1/p")
[[ -z "$CLUSTER_ID" ]] && { echo "Kafka cluster ID could not be found" ; exit 1; }
echo "Retrieved Kafka cluster ID: $CLUSTER_ID"

for ((i=1; i<=$SCHEMAS; i++))
do
  SCHEMA_PRINCIPAL="schema$i"

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${SCHEMA_PRINCIPAL}" \
  --allow-host "*" --consumer --producer --topic $SCHEMA_TOPIC --group $SCHEMA_GROUP
  [ $? -eq 1 ] && echo "Unable to create consumer and producer ACLs for topic \"$SCHEMA_TOPIC\" and principal \"$SCHEMA_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${SCHEMA_PRINCIPAL}" \
  --allow-host "*" --operation DescribeConfigs --topic $SCHEMA_TOPIC
  [ $? -eq 1 ] && echo "Unable to create describeconfigs ACL for topic \"$SCHEMA_TOPIC\" and principal \"$SCHEMA_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${SCHEMA_PRINCIPAL}" \
  --allow-host "*" --operation describe --topic $SCHEMA_TOPIC
  [ $? -eq 1 ] && echo "Unable to create describe ACL for topic \"$SCHEMA_TOPIC\" and principal \"$SCHEMA_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${SCHEMA_PRINCIPAL}" \
  --allow-host "*" --operation Read --topic $SCHEMA_TOPIC
  [ $? -eq 1 ] && echo "Unable to create read ACL for topic \"$SCHEMA_TOPIC\" and principal \"$SCHEMA_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${SCHEMA_PRINCIPAL}" \
  --allow-host "*" --operation Write --topic $SCHEMA_TOPIC
  [ $? -eq 1 ] && echo "Unable to create write ACL for topic \"$SCHEMA_TOPIC\" and principal \"$SCHEMA_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${SCHEMA_PRINCIPAL}" \
  --allow-host "*" --consumer --producer --topic $SCHEMA_ACL_TOPIC --group $SCHEMA_GROUP
  [ $? -eq 1 ] && echo "Unable to create consumer and producer ACLs for topic \"$SCHEMA_ACL_TOPIC\" and principal \"$SCHEMA_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${SCHEMA_PRINCIPAL}" \
  --allow-host "*" --operation DescribeConfigs --topic $SCHEMA_ACL_TOPIC
  [ $? -eq 1 ] && echo "Unable to create describeconfigs ACL for topic \"$SCHEMA_ACL_TOPIC\" and principal \"$SCHEMA_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${SCHEMA_PRINCIPAL}" \
  --allow-host "*" --operation describe --topic $SCHEMA_ACL_TOPIC
  [ $? -eq 1 ] && echo "Unable to create describe ACL for topic \"$SCHEMA_ACL_TOPIC\" and principal \"$SCHEMA_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${SCHEMA_PRINCIPAL}" \
  --allow-host "*" --operation Read --topic $SCHEMA_ACL_TOPIC
  [ $? -eq 1 ] && echo "Unable to create read ACL for topic \"$SCHEMA_ACL_TOPIC\" and principal \"$SCHEMA_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${SCHEMA_PRINCIPAL}" \
  --allow-host "*" --operation Write --topic $SCHEMA_ACL_TOPIC
  [ $? -eq 1 ] && echo "Unable to create write ACL for topic \"$SCHEMA_ACL_TOPIC\" and principal \"$SCHEMA_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${SCHEMA_PRINCIPAL}" \
  --allow-host "*" --operation Describe --topic $CONSUMER_OFFSETS_TOPIC
  [ $? -eq 1 ] && echo "Unable to create describe ACL for topic \"$CONSUMER_OFFSETS_TOPIC\" and principal \"$SCHEMA_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${SCHEMA_PRINCIPAL}" \
  --allow-host "*" --operation Create --cluster $CLUSTER_ID
  [ $? -eq 1 ] && echo "Unable to make create ACL for cluster \"$CLUSTER_ID\"  and principal \"$SCHEMA_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${SCHEMA_PRINCIPAL}" \
  --allow-host "*" --operation Read --topic $LICENSE_TOPIC
  [ $? -eq 1 ] && echo "Unable to create read ACL for topic \"$LICENSE_TOPIC\" and principal \"$SCHEMA_PRINCIPAL\"" && exit

  if [[ $ACL == "true" ]]; then
    sr-acl-cli --config $SCHEMA_CONFIG --add --principal $SCHEMA_PRINCIPAL --operation GLOBAL_READ
  fi
done

echo "Created general ACLs for schema registries"