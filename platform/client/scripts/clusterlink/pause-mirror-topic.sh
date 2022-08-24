#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Topic name not specified" ; exit 1; }
TOPIC=$2

kafka-mirrors --bootstrap-server $BROKER_URL --pause --topics $TOPIC --command-config $KAFKA_CONFIG

echo "Finished pausing topic $TOPIC"

# check status of mirror topic
sleep 5
kafka-mirrors --describe --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --topics $TOPIC