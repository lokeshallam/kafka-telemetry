#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

BROKER_PROTOCOL="PLAINTEXT"
REST_PROTOCOL="HTTP"
if [[ $SASL == "true" ]]; then
  BROKER_PROTOCOL="SASL_SSL"
  REST_PROTOCOL="HTTPS"
elif [[ $SSL == "true" ]]; then
  BROKER_PROTOCOL="SSL"
  REST_PROTOCOL="HTTPS"
fi

# get the kafka cluster ID
CLUSTER_ID=$(kafka-cluster cluster-id --bootstrap-server $BROKER_URL --config $KAFKA_CONFIG | sed -n "s/^Cluster ID: \(.*\)$/\1/p")
[[ -z "$CLUSTER_ID" ]] && { echo "Kafka cluster ID could not be found" ; exit 1; }
echo "Retrieved Kafka cluster ID: $CLUSTER_ID"

confluent cluster register --cluster-name $KAFKA_CLUSTER --hosts $BROKER_URL --protocol $BROKER_PROTOCOL --kafka-cluster-id $CLUSTER_ID

PREFIX="$(echo "$REST_PROTOCOL" | tr '[:upper:]' '[:lower:]')://"
SCHEMA_URL=${SCHEMA_URL#"$PREFIX"}
confluent cluster register --cluster-name $SCHEMA_CLUSTER --hosts $SCHEMA_URL --protocol $REST_PROTOCOL --kafka-cluster-id $CLUSTER_ID \
--schema-registry-cluster-id "schema-registry"

CONNECT_URL=${KAFKA_CONNECT_URL#"$PREFIX"}
confluent cluster register --cluster-name $CONNECT_CLUSTER --hosts $CONNECT_URL --protocol $REST_PROTOCOL --kafka-cluster-id $CLUSTER_ID \
--connect-cluster-id "docker-connect-cluster"

KSQL_URL=${KSQL_URL#"$PREFIX"}
confluent cluster register --cluster-name $KSQL_CLUSTER --hosts $KSQL_URL --protocol $REST_PROTOCOL --kafka-cluster-id $CLUSTER_ID \
--ksql-cluster-id "ksql-cluster"