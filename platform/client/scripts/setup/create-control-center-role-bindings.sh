#!/bin/bash

echo "Creating RBAC roles for control center"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

ROLE_TYPES=("User" "Group")
[[ -z "$2" ]] && { echo "Role binding type (${ROLE_TYPES[@]}) not specified" ; exit 1; }
[[ ! " ${ROLE_TYPES[@]} " =~ " $2 " ]] && { echo "Invalid role binding type $2 specified. Valid envs are (${ROLE_TYPES[@]})." ; exit 1; }
ROLE_TYPE=$2

PRINCIPAL="c3"
if [[ $ROLE_TYPE == "Group" ]]; then
  PRINCIPAL="c3s"
fi

MONITOR_TOPIC="_confluent-monitoring"
METRICS_TOPIC="_confluent-metrics"
COMMAND_TOPIC="_confluent-command"
C3_TOPIC="_confluent-controlcenter"

confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$COMMAND_TOPIC \
--prefix --cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$METRICS_TOPIC \
--prefix --cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$MONITOR_TOPIC \
--prefix --cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$C3_TOPIC \
--prefix --cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Group:_confluent-controlcenter --prefix \
--cluster-name $KAFKA_CLUSTER
#confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role DeveloperRead --resource Group:* --kafka-cluster-id $CLUSTER_ID
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ClusterAdmin --cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role AuditAdmin --cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role Operator --cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role SystemAdmin --cluster-name $KAFKA_CLUSTER

echo "Created RBAC roles for control center"