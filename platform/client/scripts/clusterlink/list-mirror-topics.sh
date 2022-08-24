#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

kafka-mirrors --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --describe