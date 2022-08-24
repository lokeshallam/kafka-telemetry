#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

PRINCIPAL_TYPES=("User" "Group")
[[ -z "$2" ]] && { echo "Principal type (${PRINCIPAL_TYPES[@]}) not specified" ; exit 1; }
[[ ! " ${PRINCIPAL_TYPES[@]} " =~ " $2 " ]] && { echo "Invalid principal type $2 specified. Valid values are (${PRINCIPAL_TYPES[@]})." ; exit 1; }
PRINCIPAL_TYPE=$2

[[ -z "$3" ]] && { echo "Principal name not specified" ; exit 1; }
PRINCIPAL="$3"

[[ -z "$4" ]] && { echo "Topic name not specified" ; exit 1; }
TOPIC="$4"

confluent iam rolebinding create --principal $PRINCIPAL_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$TOPIC --prefix --cluster-name $KAFKA_CLUSTER