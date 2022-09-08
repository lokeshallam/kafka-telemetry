#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh

kafka-consumer-groups --bootstrap-server $BROKER_URL --list
