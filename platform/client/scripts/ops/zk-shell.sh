#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

zookeeper-shell $ZOO3_URL -zk-tls-config-file $KAFKA_CONFIG