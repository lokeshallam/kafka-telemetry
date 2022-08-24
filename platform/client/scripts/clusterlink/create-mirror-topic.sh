#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$2

[[ -z "$3" ]] && { echo "Link not specified" ; exit 1; }
LINK=$3

kafka-mirrors --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --create --mirror-topic west-1.$TOPIC --source-topic $TOPIC --link $LINK