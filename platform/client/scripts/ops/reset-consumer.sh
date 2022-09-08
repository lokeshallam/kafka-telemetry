#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh

[[ -z "$1" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$1
[[ -z "$2" ]] && { echo "Consumer group not specified" ; exit 1; }
GROUP=$2

kafka-consumer-groups --bootstrap-server $BROKER_URL --topic $TOPIC --group $GROUP --reset-offsets --to-earliest --execute
