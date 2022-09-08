#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh

[[ -z "$1" ]] && { echo "Connector name not specified" ; exit 1; }
CONNECTOR_NAME=$1

# verify conenct server is running and accepting requests
printf "Waiting until connect server $KAFKA_CONNECT_URL is ready to accept requests"
until $(curl --output /dev/null --silent --head --fail $KAFKA_CONNECT_URL/connectors); do
  printf '.'
  sleep 3
done
echo ""
echo "Connect server $KAFKA_CONNECT_URL is ready to accept requests"

echo "Deleting $CONNECTOR_NAME connector"
curl -X DELETE $KAFKA_CONNECT_URL/connectors/$CONNECTOR_NAME
echo "Deleted $CONNECTOR_NAME connector"