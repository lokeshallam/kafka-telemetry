#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh

[[ -z "$1" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$1
[[ -z "$2" ]] && { echo "Consumer group not specified" ; exit 1; }
GROUP=$2

kafka-console-consumer --bootstrap-server $BROKER_URL \
--property print.key=true --property key.separator="  |  " \
--property print.headers=true --property headers.separator="  |  " \
--topic $TOPIC --group $GROUP --from-beginning