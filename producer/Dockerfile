FROM openjdk:11-jdk-slim
MAINTAINER My Company (it@mycompany.com)

ARG JAR_FILE
ARG JAVA_AGENT_URL
ENV JAVA_OPTS=""

RUN /bin/bash -c "echo JAR_FILE=$JAR_FILE; echo JAVA_AGENT_URL=$JAVA_AGENT_URL"
COPY $JAR_FILE /app/app.jar
ADD $JAVA_AGENT_URL /app/
ENTRYPOINT exec java $JAVA_OPTS -jar /app/app.jar