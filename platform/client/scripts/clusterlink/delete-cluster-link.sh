#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Cluster link name not specified" ; exit 1; }
NAME=$2

kafka-cluster-links --bootstrap-server $BROKER_URL --delete --link $NAME --command-config $KAFKA_CONFIG

echo "Finished deleting cluster link $NAME"