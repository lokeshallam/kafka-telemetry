#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Principal not specified" ; exit 1; }
PRINCIPAL=$2

[[ -z "$3" ]] && { echo "Operation not specified" ; exit 1; }
OPERATION=$3

[[ -z "$4" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$4

kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --topic $TOPIC --operation $OPERATION \
-resource-pattern-type LITERAL --allow-principal User:$PRINCIPAL --allow-host '*'