#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$2

[[ -z "$3" ]] && { echo "Messages not specified" ; exit 1; }
MSGS=$3 # messages per producer thread

[[ -z "$4" ]] && { echo "Threads not specified" ; exit 1; }
THREADS=$4
[[ $THREADS -gt 10 ]] && { echo "Threads cannot be greater than 10" ; exit 1; }

MSG_SIZE=102400 # message size in bytes
LOG_DIR="/tmp/perf"

# create directory to log to
mkdir -p $LOG_DIR

echo "Starting producer performance test"
echo "Launching $THREADS producer performance threads"
pids=()
for i in $(seq $THREADS); do
  kafka-producer-perf-test --producer.config $KAFKA_CONFIG --producer-props compression.type=lz4 --throughput -1 --num-records $MSGS \
  --record-size $MSG_SIZE --topic $TOPIC --print-metrics > $LOG_DIR/producer-$i-perf.log 2>&1 &
  pids[${i}]=$!
done

# wait for all pids
echo "Waiting for $THREADS producer performance threads to finish"
for pid in ${pids[*]}; do
    wait $pid
done
echo "Finished producer performance test"