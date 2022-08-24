#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$2

[[ -z "$3" ]] && { echo "Messages not specified" ; exit 1; }
MSGS=$3 # messages per producer thread

SCHEMA_USER='admin'
SCHEMA_PASSWORD='admin-secret'
TRUSTSTORE_FILENAME='kafka1.${DOMAIN}.truststore.jks'
VALUE_SCHEMA='{"type":"record","name":"test","fields":[{"name":"id","type":"long"},{"name":"name","type":"string"},{"name":"amount","type":"double"}]}'

# this and the basic auth properties being passed in the  command are hacks to get around the fact that 
# kafka-avro-console-consumer won't pull these properties properly from the $KAFKA_CONFIG
export SCHEMA_REGISTRY_OPTS="-Djavax.net.ssl.trustStore=$KEYSTORE_DIR/$TRUSTSTORE_FILENAME -Djavax.net.ssl.trustStorePassword=$KEYSTORE_PASSWORD"

for i in $(seq $MSGS); do
  kafka-avro-console-producer -bootstrap-server $BROKER_URL --producer.config $KAFKA_CONFIG \
  --batch-size 1 --compression-codec lz4 --property value.schema=$VALUE_SCHEMA --property parse.key=true --property key.separator="   " \
  --property key.deserializer=org.apache.kafka.common.serialization.LongSerializer --property schema.registry.url=$SCHEMA_URL \
  --property basic.auth.credentials.source=USER_INFO --property basic.auth.user.info=$SCHEMA_USER:$SCHEMA_PASSWORD \
  --topic $TOPIC
done