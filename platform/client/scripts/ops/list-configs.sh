#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Entity type not specified" ; exit 1; }
ENTITY_TYPE=$2

[[ -z "$3" ]] && { echo "Entity name not specified" ; exit 1; }
ENTITY_NAME=$3

kafka-configs -bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --describe --entity-type $ENTITY_TYPE --entity-name $ENTITY_NAME