FROM openjdk:11-jdk-slim
MAINTAINER My Company (it@mycompany.com)

ARG JAR_FILE
ARG JAVA_AGENT_1_URL=""
ARG JAVA_AGENT_2_URL=""
ARG JAVA_AGENT_3_URL=""
ENV JAVA_OPTS=""

RUN apt-get update; apt-get install -y curl
COPY $JAR_FILE /app/app.jar
ADD $JAVA_AGENT_1_URL /agents/
ADD $JAVA_AGENT_2_URL /agents/
ADD $JAVA_AGENT_3_URL /agents/

ENTRYPOINT exec java $JAVA_OPTS -jar /app/app.jar