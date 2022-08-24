#!/bin/bash
echo "Creating RBAC roles for KSQL servers"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

ROLE_TYPES=("User" "Group")
[[ -z "$2" ]] && { echo "Role binding type (${ROLE_TYPES[@]}) not specified" ; exit 1; }
[[ ! " ${ROLE_TYPES[@]} " =~ " $2 " ]] && { echo "Invalid role binding type $2 specified. Valid envs are (${ROLE_TYPES[@]})." ; exit 1; }
ROLE_TYPE=$2

PRINCIPAL="ksql"
if [[ $ROLE_TYPE == "Group" ]]; then
  PRINCIPAL="ksqls"
fi

SERVICE_ID="ksql-cluster"

# permission to make requests to MDS to determine if KSQL has permissions to perform required operations
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role SecurityAdmin --cluster-name $KSQL_CLUSTER

# topic and consumer group permissions

# KSQL command topic
COMMAND_TOPIC="_confluent-ksql-${SERVICE_ID}_command_topic"
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$COMMAND_TOPIC \
--cluster-name $KAFKA_CLUSTER

# KSQL processing log topic
PROCESS_LOG_TOPIC="${SERVICE_ID}ksql_processing_log"
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Topic:$PROCESS_LOG_TOPIC \
--cluster-name $KAFKA_CLUSTER

# KSQL consumer group
GROUP="_confluent-ksql-${SERVICE_ID}"
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource Group:$GROUP --prefix \
--cluster-name $KAFKA_CLUSTER

# gives KSQL access to the TransactionId resource
TX_ID="${SERVICE_ID}"
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --resource TransactionalId:$TX_ID \
--cluster-name $KAFKA_CLUSTER

# write access for the ksql service principal to the cluster
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role DeveloperWrite --resource Cluster:kafka-cluster \
--cluster-name $KAFKA_CLUSTER

# write access for the ksql service principal to the TransactionId resource
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role DeveloperWrite --resource TransactionalId:$TX_ID \
--prefix --cluster-name $KAFKA_CLUSTER

INTERCEPTOR_TOPIC="_confluent-monitoring"
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role DeveloperWrite --resource Topic:$INTERCEPTOR_TOPIC --prefix \
--cluster-name $KAFKA_CLUSTER

# permissions for topics consumed by KSQL to perform Kafka Streams operations
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role DeveloperRead --prefix --resource Topic:env.app. \
--cluster-name $KAFKA_CLUSTER
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role DeveloperWrite --prefix --resource Topic:env.app. \
--cluster-name $KAFKA_CLUSTER

ADHOC_TOPIC="_confluent-ksql-${SERVICE_ID}query_"
# permissions for topics created by KSQL to perform Kafka Streams operations
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --prefix --resource Topic:$ADHOC_TOPIC \
--cluster-name $KAFKA_CLUSTER
# TODO: figure out the exact permissions that KSQL needs for creating and retrieving schemas
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role SystemAdmin --cluster-name $SCHEMA_CLUSTER
# permissions for topics created by KSQL
confluent iam rolebinding create --principal $ROLE_TYPE:$PRINCIPAL --role ResourceOwner --prefix --resource Topic:env.ksql. \
--cluster-name $KAFKA_CLUSTER

echo "Created RBAC roles for KSQL servers"