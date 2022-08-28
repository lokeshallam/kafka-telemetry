FROM openjdk:11-jdk-slim
MAINTAINER My Company (it@mycompany.com)

ARG JMX_METRICS_JAR_URL
ENV JAVA_OPTS=""

ADD $JMX_METRICS_JAR_URL /app/
ENTRYPOINT exec java $JAVA_OPTS -jar /app/opentelemetry-jmx-metrics.jar