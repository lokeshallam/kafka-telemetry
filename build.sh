#!/bin/bash

VERSION="0.0.1"
SERVICE_NAME="java-kafka-producer"
JMX_EXPORTER_JAR="lib/jmx_prometheus_javaagent-0.16.1.jar"
JMX_AGENT_CONFIG="lib/jmx-exporter.yml"
OPEN_TELEMETRY_JAR="lib/opentelemetry-javaagent-1.16.0.jar"
JAEGER_ENDPOINT="http://jaeger:14250"

JAVA_OPTS="-Dspring.profiles.active=dev -javaagent:/app/${JMX_EXPORTER_JAR}=9100:/app/${JMX_AGENT_CONFIG} -javaagent:/app/${OPEN_TELEMETRY_JAR} -Dotel.traces.exporter=jaeger -Dotel.exporter.jaeger.endpoint=${JAEGER_ENDPOINT} -Dotel.service.name=${SERVICE_NAME}"

docker build --build-arg JAR_FILE="target/${SERVICE_NAME}-${VERSION}.jar" \
--build-arg JAVA_OPTS="${JAVA_OPTS}" \
--build-arg JMX_EXPORTER_JAR="${JMX_EXPORTER_JAR}" \
--build-arg JMX_AGENT_CONFIG="${JMX_AGENT_CONFIG}" \
--build-arg OPEN_TELEMETRY_JAR="${OPEN_TELEMETRY_JAR}" \
.