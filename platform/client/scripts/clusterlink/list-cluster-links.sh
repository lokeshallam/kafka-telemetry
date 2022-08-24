#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

kafka-cluster-links --bootstrap-server $BROKER_URL --list --command-config $KAFKA_CONFIG --include-topics