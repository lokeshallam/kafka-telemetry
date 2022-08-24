#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$2
[[ -z "$3" ]] && { echo "Consumer group not specified" ; exit 1; }
GROUP=$3

kafka-consumer-groups --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --topic $TOPIC --group $GROUP --reset-offsets --to-earliest --execute
