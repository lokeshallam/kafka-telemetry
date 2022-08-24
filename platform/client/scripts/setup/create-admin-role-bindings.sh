#!/bin/bash

echo "Creating RBAC roles for admin clients"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

ROLE_TYPES=("User" "Group")
[[ -z "$2" ]] && { echo "Role binding type (${ROLE_TYPES[@]}) not specified" ; exit 1; }
[[ ! " ${ROLE_TYPES[@]} " =~ " $2 " ]] && { echo "Invalid role binding type $2 specified. Valid envs are (${ROLE_TYPES[@]})." ; exit 1; }
ROLE_TYPE=$2

PRINCIPAL="admin"
if [[ $ROLE_TYPE == "Group" ]]; then
  PRINCIPAL="admins"
fi

confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role SystemAdmin --cluster-name $KAFKA_CLUSTER

# schema registry permissions
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role SystemAdmin --cluster-name $SCHEMA_CLUSTER
# kafka connect permissions
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role SystemAdmin --cluster-name $CONNECT_CLUSTER

# KSQL permissions
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role DeveloperWrite --cluster-name $KSQL_CLUSTER \
--resource KsqlCluster:$KSQL_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role DeveloperRead --resource Group:_confluent-ksql-$KSQL_CLUSTER --prefix \
--cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role DeveloperRead --resource Topic:${KSQL_CLUSTER}ksql_processing_log \
--cluster-name $KAFKA_CLUSTER

confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role SystemAdmin --cluster-name $KSQL_CLUSTER

echo "Created RBAC roles for admin clients"