#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh

[[ -z "$1" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$1
[[ -z "$2" ]] && { echo "Consumer group not specified" ; exit 1; }
GROUP=$2

# disable schema registry logging
export LOG_DIR="/tmp"
export SCHEMA_REGISTRY_LOG4J_LOGGERS="org.apache.kafka.clients.consumer=OFF"

echo "| KEY | VALUE | HEADERS | SCHEMA_ID |"
kafka-avro-console-consumer -bootstrap-server $BROKER_URL \
--property print.schema.ids=true --property schema.id.separator=" | " \
--property print.key=true --property key.separator=" | " --property key.deserializer=org.apache.kafka.common.serialization.LongDeserializer \
--property schema.registry.url=$SCHEMA_URL --topic $TOPIC --group $GROUP --from-beginning