#!/bin/bash

echo "Creating general ACLs for ksql"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

KSQL_PRINCIPAL="ksql1"
KSQL_GROUP_PREFIX="_confluent-ksql-ksql-cluster"
KSQL_TOPIC_PREFIX="_confluent-ksql-ksql-cluster"
KSQL_PROCCESSING_LOG="ksql-clusterksql_processing_log"
KSQL_APP_TOPIC_PREFIX="ksql.app."
KSQL_APP_GROUP_PREFIX="ksql.app."
KSQL_TRANSACTIONAL_ID="ksql-cluster"

# get the kafka cluster ID
CLUSTER_ID=$(kafka-cluster cluster-id --bootstrap-server $BROKER_URL --config $KAFKA_CONFIG | sed -n "s/^Cluster ID: \(.*\)$/\1/p")
[[ -z "$CLUSTER_ID" ]] && { echo "Kafka cluster ID could not be found" ; exit 1; }
echo "Retrieved Kafka cluster ID: $CLUSTER_ID"


# Required ACLs from  https://docs.ksqldb.io/en/latest/operate-and-deploy/installation/server-config/security/#required-acls

kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${KSQL_PRINCIPAL}" \
--allow-host "*" --operation All --topic $KSQL_TOPIC_PREFIX --resource-pattern-type prefixed
[ $? -eq 1 ] && echo "unable to make create All ACL for topic prefix \"$KSQL_TOPIC_PREFIX\" and principal \"$KSQL_PRINCIPAL\"" && exit

kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${KSQL_PRINCIPAL}" \
--allow-host "*" --operation All --group $KSQL_GROUP_PREFIX --resource-pattern-type prefixed
[ $? -eq 1 ] && echo "unable to create All ACL for group prefix \"$KSQL_TOPIC_PREFIX\" and principal \"$KSQL_PRINCIPAL\"" && exit

kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${KSQL_PRINCIPAL}" \
--allow-host "*" --operation DescribeConfigs --cluster
[ $? -eq 1 ] && echo "unable to make create DESCRIBE_CONFIGS ACL for cluster for principal \"$KSQL_PRINCIPAL\"" && exit

kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${KSQL_PRINCIPAL}" \
--allow-host "*" --operation All --topic $KSQL_PROCCESSING_LOG
[ $? -eq 1 ] && echo "unable to make create All ACL for topic \"$KSQL_PROCCESSING_LOG\" and principal \"$KSQL_PRINCIPAL\"" && exit

kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${KSQL_PRINCIPAL}" \
--allow-host "*" --operation Write --operation Describe --transactional-id $KSQL_TRANSACTIONAL_ID
[ $? -eq 1 ] && echo "unable to make create describe and write ACL for transactional ID \"$KSQL_TRANSACTIONAL_ID\" and principal \"$KSQL_PRINCIPAL\"" && exit

# Separate acls for streams apps
kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${KSQL_PRINCIPAL}" \
--allow-host "*" --consumer --group $KSQL_APP_GROUP_PREFIX --topic $KSQL_APP_TOPIC_PREFIX --resource-pattern-type prefixed
[ $? -eq 1 ] && echo "unable to create consumer ACL for topic prefix \"$KSQL_APP_TOPIC_PREFIX\" and group prefix \"$KSQL_APP_GROUP_PREFIX\" principal \"$KSQL_PRINCIPAL\"" && exit

kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${KSQL_PRINCIPAL}" \
--allow-host "*" --producer --topic $KSQL_APP_TOPIC_PREFIX --resource-pattern-type prefixed
[ $? -eq 1 ] && echo "unable to create producer ACL for topic prefix \"$KSQL_APP_TOPIC_PREFIX\" and principal \"$KSQL_PRINCIPAL\"" && exit

if [[ $ACL == "true" ]]; then
  sr-acl-cli --config $SCHEMA_CONFIG --add --principal $KSQL_PRINCIPAL --operation SUBJECT_READ --subject '*'
  sr-acl-cli --config $SCHEMA_CONFIG --add --principal $KSQL_PRINCIPAL --operation SUBJECT_WRITE --subject '*'
fi

echo "Created general ACLs for ksql"
