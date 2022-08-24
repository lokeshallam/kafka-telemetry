#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Filter type not specified (Role/Principal)" ; exit 1; }
TYPE="$2"

[[ -z "$3" ]] && { echo "Role/Principal not specified" ; exit 1; }
FILTER="--role $3"
if [[ $TYPE == "Principal" ]]; then
  FILTER="--principal $3"
fi
echo $FILTER

confluent iam rolebinding list --cluster-name $KAFKA_CLUSTER $FILTER