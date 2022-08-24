#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh

kafka-topics -bootstrap-server $BROKER_URL --list