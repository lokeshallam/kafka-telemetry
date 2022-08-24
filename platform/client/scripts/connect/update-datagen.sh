#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

# verify conenct server is running and accepting requests
printf "Waiting until connect server $KAFKA_CONNECT_URL is ready to accept requests"
until $(curl --output /dev/null --silent --head --fail $KAFKA_CONNECT_URL/connectors); do
    printf '.'
    sleep 3
done
echo ""
echo "Connect server $KAFKA_CONNECT_URL is ready to accept requests"

# create datagen connector
PUT_DATA=$(cat <<EOF
{
  "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
  "tasks.max": "1",
  "kafka.topic": "$TOPIC",
  "quickstart": "pageviews",
  "key.converter": "org.apache.kafka.connect.storage.StringConverter",
  "value.converter": "io.confluent.connect.avro.AvroConverter",
  "value.converter.schemas.enable": "false",
  "max.interval": "1000",
  "iterations": "1000",
  "producer.override.schema.registry.url": "$SCHEMA_URL"
}
EOF
)

echo "Updating datagen connector"
curl -k --header "Content-Type: application/json" -X PUT --data "$PUT_DATA" $KAFKA_CONNECT_URL/connectors/datagen
echo "Updated datagen connector"

