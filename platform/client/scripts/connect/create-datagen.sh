#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh

[[ -z "$1" ]] && { echo "Connector name not specified" ; exit 1; }
CONNECTOR_NAME=$1

[[ -z "$2" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$2

[[ -z "$3" ]] && { echo "Partitions not specified" ; exit 1; }
PARTITIONS=$3

# create input topic for datagen connector
echo "Creating datagen connector topic \"$TOPIC\""
kafka-topics --bootstrap-server $BROKER_URL --create --topic ${TOPIC} --partitions ${PARTITIONS} --replication-factor 3
echo "Created datagen connector topic \"$TOPIC\""

# verify conenct server is running and accepting requests
echo "curl --output /dev/null --silent --head --fail $KAFKA_CONNECT_URL/connectors"
printf "Waiting until connect server $KAFKA_CONNECT_URL is ready to accept requests"
until $(curl --output /dev/null --silent --head --fail $KAFKA_CONNECT_URL/connectors); do
  printf '.'
  sleep 3
done
echo ""
echo "Connect server $KAFKA_CONNECT_URL is ready to accept requests"

# create datagen connector
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
    "max.interval": "1000",
    "iterations": "10000"
  }
}
EOF
)

echo ""
echo $POST_DATA
echo ""

echo ""
echo "Creating datagen connector"
curl --header "Content-Type: application/json" -X POST --data "$POST_DATA" $KAFKA_CONNECT_URL/connectors
echo "Created datagen connector"

sleep 10
echo ""
echo "Checking status of datagen connector"
curl --header "Content-Type: application/json" $KAFKA_CONNECT_URL/connectors/$CONNECTOR_NAME/status