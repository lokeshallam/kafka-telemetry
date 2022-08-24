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

kafka-avro-console-consumer --bootstrap-server $BROKER_URL --property schema.registry.url=$SCHEMA_URL --topic $TOPIC --group $GROUP --from-beginning