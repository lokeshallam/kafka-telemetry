#!/bin/bash

CONFLUENT_LOCAL_HOME="~/programs/confluent-7.2.1"

if [[ $PATH != *"$CONFLUENT_LOCAL_HOME"* ]]; then
  PATH=$PATH:$CONFLUENT_LOCAL_HOME/bin
  export PATH
fi

DOMAIN="mycompany.com"

# registered cluster names
KAFKA_CLUSTER="kafka-cluster"
SCHEMA_CLUSTER="schema-registry-cluster"
ZOO1_URL="zoo1:2181"
BROKER_URL="kafka1.${DOMAIN}:29092"
SCHEMA_URL="http://schema1.${DOMAIN}:8081"
KAFKA_CONNECT_URL="http://connect1.${DOMAIN}:8083"