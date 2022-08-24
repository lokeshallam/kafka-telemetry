#!/bin/bash

echo "Creating general ACLs for Kafka Connect"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

WORKERS="3"
if [[ "$2" ]]; then
  WORKERS="$2"
fi

CONNECT_GROUP="docker-connect-cluster"
CONNECT_CONFIGS_TOPIC="docker-connect-configs"
CONNECT_OFFSETS_TOPIC="docker-connect-offsets"
CONNECT_STATUS_TOPIC="docker-connect-status"
CONFLUENT_MONITOR_TOPIC="_confluent-monitoring"
SECRETS_TOPIC="_confluent-secrets"
SECRETS_GROUP="secret-registry"

# get the kafka cluster ID
CLUSTER_ID=$(kafka-cluster cluster-id --bootstrap-server $BROKER_URL --config $KAFKA_CONFIG | sed -n "s/^Cluster ID: \(.*\)$/\1/p")
[[ -z "$CLUSTER_ID" ]] && { echo "Kafka cluster ID could not be found" ; exit 1; }
echo "Retrieved Kafka cluster ID: $CLUSTER_ID"


for ((i=1; i<=$WORKERS; i++))
do
  CONNECT_PRINCIPAL="connect$i"

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${CONNECT_PRINCIPAL}" \
  --allow-host "*" --operation Create --topic $CONNECT_CONFIGS_TOPIC
  [ $? -eq 1 ] && echo "unable to make create ACL for topic \"$CONNECT_CONFIGS_TOPIC\" and principal \"$CONNECT_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${CONNECT_PRINCIPAL}" \
  --allow-host "*" --operation Read --operation Write --topic $CONNECT_CONFIGS_TOPIC
  [ $? -eq 1 ] && echo "unable to create write ACL for topic \"$CONNECT_CONFIGS_TOPIC\" and principal \"$CONNECT_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${CONNECT_PRINCIPAL}" \
  --allow-host "*" --operation Create --topic $CONNECT_OFFSETS_TOPIC
  [ $? -eq 1 ] && echo "unable to make create ACL for topic \"$CONNECT_OFFSETS_TOPIC\" and principal \"$CONNECT_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${CONNECT_PRINCIPAL}" \
  --allow-host "*" --operation Read --operation Write --topic $CONNECT_OFFSETS_TOPIC
  [ $? -eq 1 ] && echo "unable to create write ACL for topic \"$CONNECT_OFFSETS_TOPIC\" and principal \"$CONNECT_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${CONNECT_PRINCIPAL}" \
  --allow-host "*" --operation Create --topic $CONNECT_STATUS_TOPIC
  [ $? -eq 1 ] && echo "unable to make create ACL for topic \"$CONNECT_STATUS_TOPIC\" and principal \"$CONNECT_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${CONNECT_PRINCIPAL}" \
  --allow-host "*" --operation Read --operation Write --topic $CONNECT_STATUS_TOPIC
  [ $? -eq 1 ] && echo "unable to create write ACL for topic \"$CONNECT_STATUS_TOPIC\" and principal \"$CONNECT_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${CONNECT_PRINCIPAL}" \
  --allow-host "*" --operation Read --group $CONNECT_GROUP
  [ $? -eq 1 ] && echo "unable to create read ACL for group \"$CONNECT_GROUP\" and principal \"$CONNECT_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${CONNECT_PRINCIPAL}" \
  --allow-host "*" --operation Describe --topic $CONFLUENT_MONITOR_TOPIC
  [ $? -eq 1 ] && echo "unable to create describe ACL for topic \"$CONFLUENT_MONITOR_TOPIC\" and principal \"$CONNECT_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${CONNECT_PRINCIPAL}" \
  --allow-host "*" --operation Write --topic $CONFLUENT_MONITOR_TOPIC
  [ $? -eq 1 ] && echo "unable to create write ACL for topic \"$CONFLUENT_MONITOR_TOPIC\" and principal \"$CONNECT_PRINCIPAL\"" && exit

  # have connect worker dynamically create DLQ topics
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${CONNECT_PRINCIPAL}" \
  --allow-host "*" --operation Create --topic "dlq." --resource-pattern-type PREFIXED
  [ $? -eq 1 ] && echo "unable to make create ACL for topic \"dlq.\" and principal \"$CONNECT_PRINCIPAL\"" && exit

  # permissions for secrets registry
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${CONNECT_PRINCIPAL}" \
  --allow-host "*" --operation All --topic $SECRETS_TOPIC
  [ $? -eq 1 ] && echo "unable to create describe ACL for topic \"$SECRETS_TOPIC\" and principal \"$CONNECT_PRINCIPAL\"" && exit

  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${CONNECT_PRINCIPAL}" \
  --allow-host "*" --group $SECRETS_GROUP
  [ $? -eq 1 ] && echo "unable to create read ACL for group \"$SECRETS_GROUP\" and principal \"$CONNECT_PRINCIPAL\"" && exit

done

echo "Created general ACLs for Kafka Connect"