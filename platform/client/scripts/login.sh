#!/bin/bash

echo "Logging into Kafka cluster"

BASE=$(dirname "$0")
cd ${BASE}
. ./env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

export CONFLUENT_USERNAME=kafka
export CONFLUENT_PASSWORD=kafka-secret

success=1
while [ $success -gt 0 ]; do
  echo "attempting to login"
  confluent login --save --url $MDS_URL --ca-cert-path=$KEYSTORE_DIR/ca.crt
  success="$?"
done

echo "Logged into Kafka cluster"