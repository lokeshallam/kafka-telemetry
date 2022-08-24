#!/bin/bash

echo "Creating RBAC roles for schema registries"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

ROLE_TYPES=("User" "Group")
[[ -z "$2" ]] && { echo "Role binding type (${ROLE_TYPES[@]}) not specified" ; exit 1; }
[[ ! " ${ROLE_TYPES[@]} " =~ " $2 " ]] && { echo "Invalid role binding type $2 specified. Valid envs are (${ROLE_TYPES[@]})." ; exit 1; }
ROLE_TYPE=$2

PRINCIPAL="schema"
if [[ $ROLE_TYPE == "Group" ]]; then
  PRINCIPAL="schemas"
fi

SCHEMA_TOPIC="_schemas"
GROUP="schema-registry"

confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$SCHEMA_TOPIC --prefix \
--cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Group:$GROUP --prefix \
--cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role SecurityAdmin --cluster-name $SCHEMA_CLUSTER

echo "Created RBAC roles for schema registries"