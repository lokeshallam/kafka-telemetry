#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Cluster link name not specified" ; exit 1; }
LINK=$2

kafka-configs --bootstrap-server $BROKER_URL --alter --cluster-link $LINK --command-config $KAFKA_CONFIG \
--add-config-file $CL_CONFIG

echo "Updated cluster link $LINK"