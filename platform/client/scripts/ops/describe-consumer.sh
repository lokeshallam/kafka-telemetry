#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh

[[ -z "$1" ]] && { echo "Consumer group not specified" ; exit 1; }
GROUP=$1

kafka-consumer-groups --bootstrap-server $BROKER_URL --describe --group $GROUP
