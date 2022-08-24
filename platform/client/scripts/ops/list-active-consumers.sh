#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

groups=()
while IFS= read -r group; do
  if [[ $group != "" ]]; then
    groups+=( "$group" )
  fi
done < <( kafka-consumer-groups --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --list )

for group in "${groups[@]}"
do
  kafka-consumer-groups --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --describe --group $group
done