#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

[[ -z "$1" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$1
[[ -z "$2" ]] && { echo "Consumer group not specified" ; exit 1; }
GROUP=$2

kafka-protobuf-console-consumer -bootstrap-server $BROKER_URL -property schema.registry.url=$SCHEMA_URL \
--property value.deserializer=io.confluent.kafka.serializers.protobuf.KafkaProtobufDeserializer \
--topic $TOPIC --group $GROUP --from-beginning