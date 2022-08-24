#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

PRINCIPAL_TYPES=("User" "Group")
[[ -z "$2" ]] && { echo "Principal type (${PRINCIPAL_TYPES[@]}) not specified" ; exit 1; }
[[ ! " ${PRINCIPAL_TYPES[@]} " =~ " $2 " ]] && { echo "Invalid principal type $2 specified. Valid values are (${PRINCIPAL_TYPES[@]})." ; exit 1; }
PRINCIPAL_TYPE="$2"

[[ -z "$3" ]] && { echo "Principal not specified" ; exit 1; }
PRINCIPAL="$3"

[[ -z "$4" ]] && { echo "Role not specified" ; exit 1; }
ROLE="$4"

# get the kafka cluster ID
CLUSTER_ID=$(kafka-cluster cluster-id --bootstrap-server $BROKER_URL --config $KAFKA_CONFIG | sed -n "s/^Cluster ID: \(.*\)$/\1/p")
[[ -z "$CLUSTER_ID" ]] && { echo "Kafka cluster ID could not be found" ; exit 1; }
echo "Retrieved Kafka cluster ID: $CLUSTER_ID"

confluent iam rolebinding delete --kafka-cluster-id $CLUSTER_ID --principal $PRINCIPAL_TYPE:$PRINCIPAL --role $ROLE