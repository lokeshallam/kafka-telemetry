#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Topic name not specified" ; exit 1; }
TOPIC_NAME=$2

[[ -z "$3" ]] && { echo "Config name not specified" ; exit 1; }
CONFIG_NAME=$3

[[ -z "$4" ]] && { echo "Config value not specified" ; exit 1; }
CONFIG_VALUE=$4

kafka-configs -bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --alter --add-config "$CONFIG_NAME=$CONFIG_VALUE" \
--entity-type topics --entity-name $TOPIC_NAME