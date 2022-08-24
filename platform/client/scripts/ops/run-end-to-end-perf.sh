#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$2

[[ -z "$3" ]] && { echo "Messages not specified" ; exit 1; }
MSGS=$3 # messages per consumer thread

MSG_SIZE=102400 # message size in bytes
PROD_ACKS="all"
LOG_DIR="/tmp/perf"

# create directory to log to
mkdir -p $LOG_DIR

echo "Starting end-to-end performance test"
kafka-run-class kafka.tools.EndToEndLatency $BROKER_URL $TOPIC $MSGS $PROD_ACKS $MSG_SIZE $KAFKA_CONFIG > $LOG_DIR/end-to-end-perf.log 2>&1
echo "Finished end-to-end performance test"