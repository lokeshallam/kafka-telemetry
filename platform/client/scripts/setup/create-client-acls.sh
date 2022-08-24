#!/bin/bash

echo "Creating general ACLs for client"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

CLIENT_GROUP_PREFIX="client."
CLIENT_TOPIC_PREFIX="client."
CLIENT_PRINCIPAL="client"
# get the kafka cluster ID
CLUSTER_ID=$(kafka-cluster cluster-id --bootstrap-server $BROKER_URL --config $KAFKA_CONFIG | sed -n "s/^Cluster ID: \(.*\)$/\1/p")
[[ -z "$CLUSTER_ID" ]] && { echo "Kafka cluster ID could not be found" ; exit 1; }
echo "Retrieved Kafka cluster ID: $CLUSTER_ID"

kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${CLIENT_PRINCIPAL}" \
--allow-host "*" --producer --topic $CLIENT_TOPIC_PREFIX --resource-pattern-type prefixed
[ $? -eq 1 ] && echo "unable to make create producer ACL for topic prefix \"$CLIENT_TOPIC_PREFIX\" and principal \"$CLIENT_PRINCIPAL\"" && exit

kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:${CLIENT_PRINCIPAL}" \
--allow-host "*" --consumer --topic $CLIENT_TOPIC_PREFIX --group $CLIENT_GROUP_PREFIX --resource-pattern-type prefixed
[ $? -eq 1 ] && echo "unable to create consumer ACL for topic prefix \"$CLIENT_TOPIC_PREFIX\" and group prefix \"$CLIENT_GROUP_PREFIX\" for principal \"$CLIENT_PRINCIPAL\"" && exit

if [[ $ACL == "true" ]]; then
  sr-acl-cli --config $SCHEMA_CONFIG --add --principal $CLIENT_PRINCIPAL --operation SUBJECT_READ --subject '*'
  sr-acl-cli --config $SCHEMA_CONFIG --add --principal $CLIENT_PRINCIPAL --operation SUBJECT_WRITE --subject '*'
fi

echo "Created general ACLs for client"
