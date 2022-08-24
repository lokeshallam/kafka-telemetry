#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "could not setup environment variables" && exit

confluent cluster describe --url $MDS_URL --ca-cert-path /var/ssl/private/ca.crt
confluent cluster describe --url $SCHEMA_URL --ca-cert-path /var/ssl/private/ca.crt
confluent cluster describe --url $KAFKA_CONNECT_URL --ca-cert-path /var/ssl/private/ca.crt
confluent cluster describe --url $KSQL_URL --ca-cert-path /var/ssl/private/ca.crt