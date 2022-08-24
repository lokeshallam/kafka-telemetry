#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Consumer group not specified" ; exit 1; }
GROUP=$2

kafka-consumer-groups --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --describe --group $GROUP
