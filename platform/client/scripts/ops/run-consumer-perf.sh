#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$2

[[ -z "$3" ]] && { echo "Group not specified" ; exit 1; }
GROUP=$3

[[ -z "$4" ]] && { echo "Messages not specified" ; exit 1; }
MSGS=$4 # messages per consumer thread

[[ -z "$5" ]] && { echo "Threads not specified" ; exit 1; }
THREADS=$5
[[ $THREADS -gt 10 ]] && { echo "Threads cannot be greater than 10" ; exit 1; }

LOG_DIR="/tmp/perf"

# create directory to log to
mkdir -p $LOG_DIR

echo "Starting consumer performance test"
echo "Launching $THREADS consumer performance threads"
pids=()
for i in $(seq $THREADS); do
  kafka-consumer-perf-test --consumer.config $KAFKA_CONFIG --bootstrap-server $BROKER_URL --group $GROUP --topic $TOPIC \
  --messages $MSGS --show-detailed-stats --print-metrics > $LOG_DIR/consumer-$i-perf.log 2>&1 &
  pids[${i}]=$!
done

# wait for all pids
echo "Waiting for $THREADS consumer performance threads to finish"
for pid in ${pids[*]}; do
    wait $pid
done
echo "Finished consumer performance test"