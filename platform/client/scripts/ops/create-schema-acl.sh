#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Principal not specified" ; exit 1; }
PRINCIPAL=$2

[[ -z "$3" ]] && { echo "Operation not specified" ; exit 1; }
OPERATION=$3

SUBJECT=""
if [[ ! $OPERATION = GLOBAL_* ]]; then

  [[ -z "$4" ]] && { echo "Subject not specified" ; exit 1; }
  SUBJECT="--subject $4"

fi

sr-acl-cli --config $KAFKA_CONFIG --operation $OPERATION $SUBJECT --principal $PRINCIPAL --add