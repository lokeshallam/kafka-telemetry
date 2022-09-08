#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh

[[ -z "$1" ]] && { echo "Connector name not specified" ; exit 1; }
CONNECTOR_NAME=$1

# create DLQ topic for jdbcsink connector
DLQ="demo.dlq"
echo "Creating jdbcsink connector topic \"$DLQ\""
kafka-topics --bootstrap-server $BROKER_URL --create --topic $DLQ --partitions 1
echo "Created jdbcsink connector topic \"$DLQ\""

GROUP=$CONNECTOR_NAME

# verify conenct server is running and accepting requests
printf 'Waiting until connect server REST API is ready to accept requests'
until $(curl --output /dev/null --silent --head --fail $KAFKA_CONNECT_URL/connectors); do
  printf '.'
  sleep 3
done
echo ""
echo "Connect server REST API is ready to accept requests"

# create jdbc sink connector
POST_DATA=$(cat <<EOF
{
  "name": "$CONNECTOR_NAME",
  "config": {
    "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
    "tasks.max": "1",
    "batch.size": "100",
    "connection.url": "jdbc:postgresql://postgres:5432/kafka",
    "connection.user": "postgres",
    "connection.password": "postgrespass",
    "topics.regex": "demo\\\\.transform\\\\..*",
    "table.name.format": "\${topic}",
    "auto.create": "true",
    "auto.evolve": "true",
    "pk.mode": "record_key",
    "pk.fields": "id",
    "insert.mode": "upsert",
    "delete.enabled": "true",
    "errors.tolerance": "all",
    "errors.deadletterqueue.topic.name": "$DLQ",
    "errors.deadletterqueue.topic.replication.factor": 3,
    "errors.deadletterqueue.context.headers.enable": "true",
    "errors.retry.delay.max.ms": 10000,
    "errors.retry.timeout": 30000,
    "errors.log.enable": "true",
    "errors.log.include.messages": "true",
    "key.converter": "org.apache.kafka.connect.converters.LongConverter",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "$SCHEMA_URL",
    "value.converter.schemas.enable": "true",
    "consumer.override.group.id": "$GROUP",
    "producer.override.client.id": "jdbcsink-producer",
    "transforms":"dropPrefix",
    "transforms.dropPrefix.type":"org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.dropPrefix.regex":"demo\\\\.transform\\\\.(.*)",
    "transforms.dropPrefix.replacement":"public.\$1"
  }
}
EOF
)

echo ""
echo "Creating jdbcsink connector"
curl --header "Content-Type: application/json" -X POST --data "$POST_DATA" $KAFKA_CONNECT_URL/connectors
echo ""
echo "Created jdbcsink connector"

sleep 10
echo ""
echo "Checking status of jdbcsink connector"
curl $KAFKA_CONNECT_URL/connectors/$CONNECTOR_NAME/status