#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

kafka-consumer-groups --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --list
