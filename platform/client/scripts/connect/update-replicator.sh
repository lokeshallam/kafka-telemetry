#!/bin/bash

CONNECT_SERVER_USER="user"
CONNECT_SERVER_PASSWORD="password"
CONNECT_SERVER_URL="https://localhost:8083"

printf 'Waiting until connect server REST API is ready to accept requests'
until $(curl --output /dev/null --silent --head --fail -u ${CONNECT_SERVER_USER}:${CONNECT_SERVER_PASSWORD} ${CONNECT_SERVER_URL}/connectors); do
    printf '.'
    sleep 3
done
echo ""
echo "Connect server REST API is ready to accept requests"

PUT_DATA=$(cat <<EOF
{
    "connector.class": "io.confluent.connect.replicator.ReplicatorSourceConnector",
    "topic.regex": ".*",
    "topic.whitelist": "",
    "topic.poll.interval.ms": "120000",
    "src.kafka.bootstrap.servers": "",
    "src.kafka.client.id": "",
    "src.kafka.timestamps.topic.replication.factor": "3",
    "src.kafka.security.protocol": "SASL_SSL",
    "src.kafka.sasl.mechanism": "GSSAPI",
    "src.kafka.sasl.kerberos.service.name": "cp-kafka",
    "src.kafka.ssl.keystore.location": "",
    "src.kafka.ssl.keystore.password": "",
    "src.kafka.ssl.truststore.location": "",
    "src.kafka.ssl.truststore.password": "",
    "src.kafka.ssl.key.password": "",
    "src.consumer.max.poll.records": "500",
    "topic.rename.format": "${topic}",
    "topic.auto.create": "true",
    "topic.preserve.partitions": "true",
    "offset.topic.commit": "false",
    "topic.config.sync": "true",
    "topic.config.sync.interval.ms": "120000",
    "dest.topic.replication.factor": "3",
    "dest.kafka.bootstrap.servers": "",
    "dest.kafka.client.id": "",
    "dest.kafka.security.protocol": "SASL_SSL",
    "dest.kafka.sasl.mechanism": "GSSAPI",
    "dest.kafka.sasl.kerberos.service.name": "cp-kafka",
    "dest.kafka.ssl.keystore.location": "",
    "dest.kafka.ssl.keystore.password": "",
    "dest.kafka.ssl.truststore.location": "",
    "dest.kafka.ssl.truststore.password": "",
    "confluent.topic.bootstrap.servers": "",
    "confluent.license": "",
    "confluent.topic.security.protocol": "SASL_SSL",
    "confluent.topic.sasl.mechanism": "GSSAPI",
    "confluent.topic.sasl.kerberos.service.name": "cp-kafka",
    "confluent.topic.ssl.keystore.location": "",
    "confluent.topic.ssl.keystore.password": "",
    "confluent.topic.ssl.truststore.location": "",
    "confluent.topic.ssl.truststore.password": ""
}
EOF
)

echo "$POST_DATA"
echo ''
curl -k --header "Content-Type: application/json" --request PUT --data "$PUT_DATA" -u ${CONNECT_SERVER_USER}:${CONNECT_SERVER_PASSWORD} ${CONNECT_SERVER_URL}/connectors/replicator