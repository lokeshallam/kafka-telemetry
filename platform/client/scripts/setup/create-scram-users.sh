#!/bin/bash

echo "Creating Scram user entities in Zookeeper"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

export KAFKA_OPTS=-Djava.security.auth.login.config=/etc/kafka/secrets/zoo-client-jaas.conf

kafka-configs --zookeeper $ZOO1_URL --zk-tls-config-file $KAFKA_CONFIG --alter --entity-type users --entity-name kafka \
--add-config 'SCRAM-SHA-256=[password=kafka-secret],SCRAM-SHA-512=[password=kafka-secret]'

kafka-configs --zookeeper $ZOO1_URL --zk-tls-config-file $KAFKA_CONFIG --alter --entity-type users --entity-name schema \
--add-config 'SCRAM-SHA-256=[password=schema-secret],SCRAM-SHA-512=[password=schema-secret]'

kafka-configs --zookeeper $ZOO1_URL --zk-tls-config-file $KAFKA_CONFIG --alter --entity-type users --entity-name connect \
--add-config 'SCRAM-SHA-256=[password=connect-secret],SCRAM-SHA-512=[password=connect-secret]'

kafka-configs --zookeeper $ZOO1_URL --zk-tls-config-file $KAFKA_CONFIG --alter --entity-type users --entity-name c3 \
--add-config 'SCRAM-SHA-256=[password=c3-secret],SCRAM-SHA-512=[password=c3-secret]'

kafka-configs --zookeeper $ZOO1_URL --zk-tls-config-file $KAFKA_CONFIG --alter --entity-type users --entity-name datagen \
--add-config 'SCRAM-SHA-256=[password=datagen-secret],SCRAM-SHA-512=[password=datagen-secret]'

kafka-configs --zookeeper $ZOO1_URL --zk-tls-config-file $KAFKA_CONFIG --alter --entity-type users --entity-name jdbcsink \
--add-config 'SCRAM-SHA-256=[password=jdbcsink-secret],SCRAM-SHA-512=[password=jdbcsink-secret]'

kafka-configs --zookeeper $ZOO1_URL --zk-tls-config-file $KAFKA_CONFIG --alter --entity-type users --entity-name admin \
--add-config 'SCRAM-SHA-256=[password=admin-secret],SCRAM-SHA-512=[password=admin-secret]'

kafka-configs --zookeeper $ZOO1_URL --zk-tls-config-file $KAFKA_CONFIG --alter --entity-type users --entity-name client \
--add-config 'SCRAM-SHA-256=[password=client-secret],SCRAM-SHA-512=[password=client-secret]'

echo "Finished creating Scram user entities in Zookeeper"