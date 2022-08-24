#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

BASIC_AUTH=""
if [[ $SASL == "true" ]]; then
  BASIC_AUTH="-u connect:connect-secret"
fi

# verify conenct server is running and accepting requests
printf "Waiting until connect server $KAFKA_CONNECT_URL is ready to accept requests"
until $(curl -k $BASIC_AUTH --output /dev/null --silent --head --fail $KAFKA_CONNECT_URL/connectors); do
  printf '.'
  sleep 3
done
echo ""
echo "Connect server $KAFKA_CONNECT_URL is ready to accept requests"

echo "Deleting datagen connector"
curl -k $BASIC_AUTH --header "Content-Type: application/json" -X DELETE $KAFKA_CONNECT_URL/connectors/datagen
echo "Deleted datagen connector"