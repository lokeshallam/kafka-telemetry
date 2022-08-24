#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

OFFSETS_TOPIC="docker-connect-offsets"
TASKS=("0")

echo "Clearing out connector offsets for datagen connector"
for TASK in $TASKS; do echo "[\"datagen\",{\"task.id\":$TASK}]~"; done | kafka-console-producer --bootstrap-server $BROKER_URL --producer.config $KAFKA_CONFIG --topic $OFFSETS_TOPIC --property parse.key=true --property key.separator=~
echo "Successfully cleared offsets for datagen connector"