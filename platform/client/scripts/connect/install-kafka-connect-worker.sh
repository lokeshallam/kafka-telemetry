#!/bin/bash

INSTALL_DIR="/tmp"
#INSTALL_DIR="/data01/confluent"
CLUSTER_URL="lkc-9kpd07-g4r036.southcentralus.azure.glb.confluent.cloud:9092"
CONNECT_API_KEY="connect-key"
CONNECT_API_SECRET="connect-secret"
SCHEMA_REGISTRY_URL="https://psrc-kg7rp.westus2.azure.confluent.cloud"
SCHEMA_API_KEY="sr-key"
SCHEMA_API_SECRET="sr-secret"
VERSION="7.2.1"

BIN_DIR="${INSTALL_DIR}/confluent-${VERSION}/bin"
CONF_DIR="${INSTALL_DIR}/confluent-${VERSION}/etc/kafka"
CONNECT_CONF="connect-distributed.properties"
SVC_CONF_DIR="/usr/lib/systemd/system"
SVC_NAME="confluent-kafka-connect.service"

# download confluent platform package and unzip in installation directory
cd ${INSTALL_DIR}
curl -O http://packages.confluent.io/archive/${VERSION}/confluent-${VERSION}.tar.gz
tar xzf confluent-${VERSION}.tar.gz
rm confluent-${VERSION}tar.gz

# create linux user and group to run service
sudo useradd -M cp-kafka-connect
sudo usermod -L cp-kafka-connect
sudo groupadd confluent
sudo usermod -a -G confluent cp-kafka-connect

# create kafka connect config properties file
cat <<EOF
bootstrap.servers=${CLUSTER_URL}
key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=io.confluent.connect.avro.AvroConverter
ssl.endpoint.identification.algorithm=https security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="${CONNECT_API_KEY}" password="${CONNECT_API_SECRET}"; 
request.timeout.ms=20000
retry.backoff.ms=500
producer.bootstrap.servers=${CLUSTER_URL}
producer.ssl.endpoint.identification.algorithm=https
producer.security.protocol=SASL_SSL
producer.sasl.mechanism=PLAIN
producer.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="${CONNECT_API_KEY}" password="${CONNECT_API_SECRET}"; producer.request.timeout.ms=20000
producer.retry.backoff.ms=500
consumer.bootstrap.servers=${CLUSTER_URL}
consumer.ssl.endpoint.identification.algorithm=https
consumer.security.protocol=SASL_SSL
consumer.sasl.mechanism=PLAIN
consumer.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="${CONNECT_API_KEY}" password="${CONNECT_API_SECRET}"; consumer.request.timeout.ms=20000
consumer.retry.backoff.ms=500 offset.flush.interval.ms=10000
offset.storage.file.filename=/tmp/connect.offsets
group.id=connect-cluster
offset.storage.topic=connect-offsets
offset.storage.replication.factor=3
offset.storage.partitions=3
config.storage.topic=connect-configs
config.storage.replication.factor=3
status.storage.topic=connect-status
status.storage.replication.factor=3
# Required connection configs for Confluent Cloud Schema Registry
value.converter.basic.auth.credentials.source=USER_INFO
value.converter.schema.registry.basic.auth.user.info=${SCHEMA_API_KEY}:${SCHEMA_API_SECRET}
value.converter.schema.registry.url=${SCHEMA_REGISTRY_URL}
EOF
) > ${CONNECT_CONF}

# create confluent-kafka-connect systemd service
cd /usr/lib/systemd/system/
cat <<EOF
[Unit]
Description=Confluent Kafka Connect
Documentation=http://confluent.io/
After=network.target

[Service]
Type=simple
User=cp-kafka-connect
Group=confluent
ExecStart=${BIN_DIR}/connect-distributed.sh ${CONF_DIR}/${CONNECT_CONF}
TimeoutStopSec=180
Restart=yes

[Install]
WantedBy=multi-user.target
EOF
) > ${SVC_NAME}

# set directory permissions
sudo chmod 744 ${BIN_DIR}
sudo chmod 664 ${SVC_CONF_DIR}/${SVC_NAME}
sudo systemctl daemon-reload
sudo systemctl enable ${SVC_NAME}

