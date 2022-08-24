#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Topic not specified" ; exit 1; }
TOPIC=$2
[[ -z "$3" ]] && { echo "Consumer group not specified" ; exit 1; }
GROUP=$3

# this and the basic auth properties being passed in the  command are hacks to get around the fact that 
# kafka-avro-console-consumer won't pull these properties properly from the $KAFKA_CONFIG
TRUSTSTORE_FILENAME="kafka1.mycompany.com.truststore.jks"
echo 
export SCHEMA_REGISTRY_OPTS="-Djavax.net.ssl.trustStore=$KEYSTORE_DIR/$TRUSTSTORE_FILENAME -Djavax.net.ssl.trustStorePassword=$KEYSTORE_PASSWORD"

kafka-console-consumer -bootstrap-server $BROKER_URL --consumer.config $KAFKA_CONFIG \
--property schema.registry.url=$SCHEMA_URL --property basic.auth.credentials.source=USER_INFO --property basic.auth.user.info=admin:admin-secret \
--property key.deserializer=io.confluent.databalancer.persistence.SbkApiStatusMessageSerde --property value.deserializer=io.confluent.databalancer.persistence.SbkApiStatusMessageSerde \
--topic $TOPIC --group $GROUP --from-beginning