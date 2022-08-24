#!/bin/bash

echo "Creating RBAC roles for Kafka Connect servers"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

ROLE_TYPES=("User" "Group")
[[ -z "$2" ]] && { echo "Role binding type (${ROLE_TYPES[@]}) not specified" ; exit 1; }
[[ ! " ${ROLE_TYPES[@]} " =~ " $2 " ]] && { echo "Invalid role binding type $2 specified. Valid envs are (${ROLE_TYPES[@]})." ; exit 1; }
ROLE_TYPE=$2

PRINCIPAL="connect"
if [[ $ROLE_TYPE == "Group" ]]; then
  PRINCIPAL="connects"
fi

CONFIGS_TOPIC="docker-connect-configs"
OFFSETS_TOPIC="docker-connect-offsets"
STATUS_TOPIC="docker-connect-status"
GROUP="docker-connect-cluster"
SECRETS_TOPIC="_confluent-secrets"
SECRETS_GROUP="secret-registry"

confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$CONFIGS_TOPIC \
--cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$OFFSETS_TOPIC \
--cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$STATUS_TOPIC \
--cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Group:$GROUP \
--cluster-name $KAFKA_CLUSTER
# permissions for secrets registry
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$SECRETS_TOPIC \
--cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Group:$SECRETS_GROUP \
--cluster-name $KAFKA_CLUSTER
# to make requests to MDS to determine if the connector user is authorized to perform required operations
#confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role SecurityAdmin --cluster-name $CONNECT_CLUSTER
# have connect worker dynamically create DLQ topics
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:dlq. --prefix \
--cluster-name $KAFKA_CLUSTER
# permissions to submit connectors and make requests to MDS to determine if connector has permissions to perform required operations
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role SystemAdmin --cluster-name $CONNECT_CLUSTER

echo "Created RBAC roles for Kafka Connect servers"