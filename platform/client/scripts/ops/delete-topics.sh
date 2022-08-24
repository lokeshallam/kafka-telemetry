#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$2

kafka-topics -bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --delete --topic $TOPIC
