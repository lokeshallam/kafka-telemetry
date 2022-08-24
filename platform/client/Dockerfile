FROM openjdk:11-jdk-slim
RUN apt-get update; apt-get install -y curl
ADD http://packages.confluent.io/archive/7.2/confluent-7.2.1.tar.gz /
RUN tar xzf confluent-7.2.1.tar.gz
ENV PATH=$PATH:/confluent-7.2.1/bin
