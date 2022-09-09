# kafka-telemetry

## Summary

This is a demo project to test out the capabilities of different telemetry tools with Kafka. The project contains:

* Kafka Producer
* Kafka Streams Application
* Kafka Consumer
* Platform folder with various docker-compose files

## Requirements

This project requires the following tools:

* [OpenJDK](https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz)
* [Maven](https://dlcdn.apache.org/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.zip)
* [docker & docker-compose](https://desktop.docker.com/mac/main/amd64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=dd-smartbutton&utm_location=module)

## Build Project

Make sure that [Maven](https://dlcdn.apache.org/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.zip) is in your path
and that [docker](https://desktop.docker.com/mac/main/amd64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=dd-smartbutton&utm_location=module)
is running. To build the project, go to the base directory and run `mvn install`. This will compile the Java classes for
`java-kafka-consumer`, `java-kafka-producer`, and `java-kafka-streams` and create bootable jar files for each. Then it
will generate `docker` images for each and push them to your local repo. The `Dockerfile` for each project is located in
the base directory for each module.

## Setup Project

Now that the Kafka clients are built and have `docker` images in your local repo, you can run an observability environment
by going into the `platform` directory of this project and running the `setup.sh` script. An argument is passed to this 
script that indicates which `docker-compose` file to run. All scripts will launch [Zookeeper](https://zookeeper.apache.org/), 
[Kafka](https://kafka.apache.org/) brokers, and the [Confluent Schema Registry](https://docs.confluent.io/platform/current/schema-registry/index.html).
In addition, it may launch [Kafka Connect](https://docs.confluent.io/platform/current/connect/index.html) workers. Also,
the `java-kafka-consumer`, `java-kafka-producer`, and `java-kafka-streams` applications will be launched and start processing
messages as described below.

1) `java-kafka-producer` will generate an Avro message and send it to the topic `demo.customer` every second
2) `java-kafka-streams` will consume the message from the topic `demo.customer` and send it to the topic `demo.transform.customer`
3) `java-kafka-consumer` will consume the message from the topic `demo.transform.customer` and print its contents to the console

While the Kafka applications are streaming messages, they are configured to send tracing data to an observability tool.
This allows you to see the path of the messages through the applications and the time taken for each step even though 
they are running as different processes. The observability tools available to use in this demo project are [Jaeger](https://www.jaegertracing.io/),
[Dynatrace](https://www.dynatrace.com/) and [OpenTelemetry](https://opentelemetry.io/) exporting to [Jaeger](https://www.jaegertracing.io/).
[Splunk](https://www.splunk.com/) was setup as well but is not working at this point. 

### Jaeger Setup

To start the Kafka Jaeger tracing demo, go in the `platform` folder and run this command:
```
./setup.sh jaeger
```
In addition to launching Zookeeper, Kafka brokers, Confluent Schema Registry, Kafka Connect workers, and the 
`java-kafka-consumer`, `java-kafka-producer`, and `java-kafka-streams` applications, this demo will also launch 
[Jaeger all-in-one](https://hub.docker.com/r/jaegertracing/all-in-one/) and [Prometheus](https://prometheus.io/) for
metrics collection. The Kafka applications are using the [OpenTelemetry Java agent](https://github.com/open-telemetry/opentelemetry-java-instrumentation)
to send trace data to Jaeger. This agent uses the [Java Instrumentation API](https://www.baeldung.com/java-instrumentation)
to modify the bytecode of compiled Java applications to insert bytecode that sends trace data to an observability tool
based on the agent's configuration. The configuration can be seen in the file `platform/jaeger.yml` in the services
`producer1`, `kstream1` and `consumer1`.

```
  producer1:
    image: com.mycompany/java-kafka-producer:0.0.1
    ...
    environment:
    ...
      OTEL_SERVICE_NAME: "producer1"
      OTEL_TRACES_EXPORTER: "jaeger"
      OTEL_EXPORTER_JAEGER_ENDPOINT: "http://jaeger:14250"
      OTEL_METRICS_EXPORTER: "none"
      OTEL_TRACES_SAMPLER: "traceidratio"
      OTEL_TRACES_SAMPLER_ARG: "0.5"
    ...
      JAVA_OPTS: >-
        ...
        -javaagent:/agents/opentelemetry-javaagent.jar
```

Once the `setup.sh` command has finished, run `docker ps -a` to see if all the processes are running and are healthy. You
should see something like this:

```
% docker ps -a

CONTAINER ID   IMAGE                                     COMMAND                   CREATED          STATUS                    PORTS                                                                                              NAMES
8c778d125b59   com.mycompany/java-kafka-consumer:0.0.1   "/bin/sh -c 'exec ja…"    17 minutes ago   Up 13 minutes (healthy)   0.0.0.0:9002->9002/tcp, 0.0.0.0:9102->9102/tcp                                                     consumer1
7eda7b14bc56   com.mycompany/java-kafka-streams:0.0.1    "/bin/sh -c 'exec ja…"    17 minutes ago   Up 15 minutes (healthy)   0.0.0.0:9001->9001/tcp, 0.0.0.0:9101->9101/tcp                                                     kstream1
ad06337883fb   kafka-client:0.0.1                        "bash -c 'cd /script…"    19 minutes ago   Up About a minute (healthy)                                                                                                  client                                                                                                                client
ce28abef6117   confluentinc/cp-server-connect:7.2.1      "bash -c 'echo \"Inst…"   17 minutes ago   Up 15 minutes (healthy)   0.0.0.0:8083->8083/tcp, 9092/tcp                                                                   connect1
38694c81df70   com.mycompany/java-kafka-producer:0.0.1   "/bin/sh -c 'exec ja…"    17 minutes ago   Up 15 minutes (healthy)   0.0.0.0:9000->9000/tcp, 0.0.0.0:9100->9100/tcp                                                     producer1
f122f7b37b8f   nginx:1.21.6                              "/docker-entrypoint.…"    17 minutes ago   Up 16 minutes             0.0.0.0:9092->9092/tcp, 80/tcp, 0.0.0.0:29092->29092/tcp                                           lb
f9c448b18910   confluentinc/cp-schema-registry:7.2.1     "/etc/confluent/dock…"    17 minutes ago   Up 16 minutes (healthy)   0.0.0.0:8081->8081/tcp                                                                             schema1
69a67dd4d488   confluentinc/cp-server:7.2.1              "/etc/confluent/dock…"    17 minutes ago   Up 16 minutes (healthy)   0.0.0.0:9093->9093/tcp, 9092/tcp, 0.0.0.0:29093->29093/tcp                                         kafka1
52f85e532672   confluentinc/cp-server:7.2.1              "/etc/confluent/dock…"    17 minutes ago   Up 16 minutes (healthy)   0.0.0.0:9094->9094/tcp, 9092/tcp, 0.0.0.0:29094->29094/tcp                                         kafka2
9d094b9590d6   confluentinc/cp-server:7.2.1              "/etc/confluent/dock…"    17 minutes ago   Up 16 minutes (healthy)   0.0.0.0:9095->9095/tcp, 9092/tcp, 0.0.0.0:29095->29095/tcp                                         kafka3
29a56fd64c51   ubuntu/prometheus                         "/usr/bin/prometheus…"    17 minutes ago   Up 17 minutes             0.0.0.0:9090->9090/tcp                                                                             prometheus
ba61e3fb132a   postgres                                  "docker-entrypoint.s…"    17 minutes ago   Up 17 minutes             0.0.0.0:5432->5432/tcp                                                                             postgres
dd6350657712   confluentinc/cp-zookeeper:7.2.1           "/etc/confluent/dock…"    17 minutes ago   Up 17 minutes (healthy)   2888/tcp, 0.0.0.0:2181->2181/tcp, 3888/tcp                                                         zoo1
2c3fbe14dbd6   jaegertracing/all-in-one:latest           "/go/bin/all-in-one-…"    17 minutes ago   Up 17 minutes             5775/udp, 5778/tcp, 0.0.0.0:14250->14250/tcp, 6831-6832/udp, 14268/tcp, 0.0.0.0:16686->16686/tcp   jaeger
```

To see the tracing data, open up a browser and go to [Jaeger's UI](`http://localhost:16686/`). In the upper right corner
you can search for traces by trace ID. You can get the trace IDs from the logs of `kstream1` or `consumer1`. To view these
logs execute `docker logs kstream1 -n 500 -f`. You should see something like this in the command window:

```
2022-09-08 16:05:23 - c.m.k.s.StatelessTopologyBuilder - consumer headers: trace_id=ff1abc79aef6a9b7955fe519e282130e span_id=33882d0afd07dee2 trace_flags=01
2022-09-08 16:05:23 - c.m.k.s.StatelessTopologyBuilder - traceparent=00-ff1abc79aef6a9b7955fe519e282130e-d3e9bfa81601b723-01 trace_id=ff1abc79aef6a9b7955fe519e282130e span_id=33882d0afd07dee2 trace_flags=01
2022-09-08 16:05:24 - c.m.k.s.StatelessTopologyBuilder - consumer headers: trace_id=6ff30376f7aa079edea8000fb2a76df4 span_id=3337ec16f40867b9 trace_flags=01
2022-09-08 16:05:24 - c.m.k.s.StatelessTopologyBuilder - traceparent=00-6ff30376f7aa079edea8000fb2a76df4-844276bf55d2ca48-01 trace_id=6ff30376f7aa079edea8000fb2a76df4 span_id=3337ec16f40867b9 trace_flags=01
2022-09-08 16:05:25 - c.m.k.s.StatelessTopologyBuilder - consumer headers: trace_id=90bca7c3c4b16efbaf1ec54f48eab468 span_id=10f3ddd8d818c9a0 trace_flags=01
2022-09-08 16:05:25 - c.m.k.s.StatelessTopologyBuilder - traceparent=00-90bca7c3c4b16efbaf1ec54f48eab468-d3feb0e54e201af1-01 trace_id=90bca7c3c4b16efbaf1ec54f48eab468 span_id=10f3ddd8d818c9a0 trace_flags=01
2022-09-08 16:05:26 - c.m.k.s.StatelessTopologyBuilder - consumer headers: trace_id=c7a2718bba2bedb19bfe865ad1c42a56 span_id=63f38ae609f58f75 trace_flags=01
2022-09-08 16:05:26 - c.m.k.s.StatelessTopologyBuilder - traceparent=00-c7a2718bba2bedb19bfe865ad1c42a56-203bc199a840b29b-01 trace_id=c7a2718bba2bedb19bfe865ad1c42a56 span_id=63f38ae609f58f75 trace_flags=01
```

Trace data is passed through Kafka topics by putting the data in the message header. The message header key for the
trace data is `traceparent` and the value is a combination of `trace_id`, `span_id` and `trace_flags` in this format
`00-<trace_id>-<span_id>-<trace_flags>`. A span is a term used to identify a single process of an application. In the 
case of Kafka, think of it as sending or receiving a message. A trace is all the spans that have processed a 
particular message. If you want to see the actual message headers from a Kafka topic, you can use the `client` container
included in this project.

1) Shell into the `client` container by executing the command `docker exec -it client /bin/bash`.
2) Inside the `client` container, execute the command `cd /scripts/ops` to go to the operations scripts directory.
3) Inside the `client` container, execute the command `./consume-topic.sh demo.customer my-consumer-group`. You should see something like this in the console:

```
traceparent:00-d62bd73b1005e36979fe03694b374aa5-424addfd1463e4e3-01  |  iO>��>  |  ������JoshBerniervwkqztjgnd�����^�≫`
traceparent:00-16e671730ca0a1f713cc74a8eaecfe21-1aba40e54247eb4f-01  |  i�G���  |  ����܅�
JustaCorkeryipqonoobbp�Ư��_��҄�`
traceparent:00-aac4df23fea8fb07e3b97ec89d27c583-993d4a513629347a-01  |  -E���  |  ���ꢔZ
                                                                                       Darius
                                                                                             Raynorlapostktau�����`ȇ���_
traceparent:00-5a560ef64256ee362faa8a0efe50472f-8e99c62fcf6b3b44-01  | B
                                                                        �x��  |  ����ƅ�
BrettStrosinxoygabbstx₷��_�����`
traceparent:00-27796f1b6a93cee3bc30a85f550d28e4-0ced6c2bca8ba9b9-01  |  A#����  |  ����ޣ�MagdalenKrajciktxtidjkgmi�����_Ɓ���`
traceparent:00-05ec49280122fd40f99742deb1cda287-bce8f3b3ed43ac1d-01  |  8�&��ܦ  |  �����qMaybell
                                                                                                Baileywqkyxrsfbr���_��Ğ_
```

This first part of each line (up to the first `|`) is the message headers. In the example above, this is the first 
message header listed: `traceparent:00-d62bd73b1005e36979fe03694b374aa5-424addfd1463e4e3-01`. This is the same format as 
was described above in the application logs, where `d62bd73b1005e36979fe03694b374aa5` is the `trace_id` and 
`424addfd1463e4e3` is the `span_id`. If you take any one of the `trace_id`, copy and paste it into the [Jaeger UI](http://localhost:16686/), 
You will see the full trace for that message. You should see the following spans from top to bottom:

* `producer1 demo.customer send` - the `producer1` application sending the message to the topic `demo.customer`
* `kstream1 demo.customer process` - the `kstream1` application receiving the message from the topic `demo.customer`
* `kstream1 demo.transform.customer send` - the `kstream1` application sending the message to the topic `demo.transform.customer`
* `connect1 demo.transform.customer process` - the `connect1` JDBC sink connector receiving the message from the topic `demo.transform.customer` 
* `consumer1 demo.transform.customer process` - the `consumer1` application receiving the message from the topic `demo.transform.customer`

You can also use the `Search` feature just to pull up the last 20 traces recorded.

### Jaeger Teardown

Once you are finished with the Kafka Jaeger tracing demo, go in the `platform` folder and run this command:
```
./teardown.sh jaeger
```
This will stop all the running docker containers for this project and cleanup the data volumes used by each in the 
folder `platform/volumes`.

### OTEL Jaeger Setup

To start the Kafka OTEL Collector Jaeger tracing demo, go in the `platform` folder and run this command:
```
./setup.sh otel-jaeger
```
In addition to launching Zookeeper, Kafka brokers, Confluent Schema Registry, Kafka Connect workers, and the
`java-kafka-consumer`, `java-kafka-producer`, and `java-kafka-streams` applications, this demo will also launch
[Jaeger all-in-one](https://hub.docker.com/r/jaegertracing/all-in-one/) and the [OTEL Collector](https://github.com/open-telemetry/opentelemetry-collector) 
for metrics collection. The Kafka applications are using the [OpenTelemetry Java agent](https://github.com/open-telemetry/opentelemetry-java-instrumentation)
to send trace data to the OTEL Collector which forwards the data to Jaeger. This agent uses the [Java Instrumentation API](https://www.baeldung.com/java-instrumentation)
to modify the bytecode of compiled Java applications to insert bytecode that sends trace data to an observability tool
based on the agent's configuration. The configuration can be seen in the file `platform/jaeger.yml` in the services
`producer1`, `kstream1` and `consumer1`. The advantage of using the OTEL Collector is that it can collect trace data sent
from several clients and forward it to the destination telemetry system in batches. This is especially advantageous when
the end telemetry system is in the cloud. The OTEL Collector should be deployed near the clients so network latency is 
minimal.

The OTEL Collector configuration is defined in the file `platform/otel/otel-collector-jaeger.yml`. The `receivers` 
section defines how the OTEL Collector will receive data from the clients.
```
receivers:
  otlp:
    protocols:
      grpc:
```
The `exporters` section defines the endpoints where the OTEL Collector is sending data. In this case, one endpoint is
defined for Jaeger.
```
exporters:
  jaeger:
    endpoint: jaeger.mycompany.com:14250
      tls:
        insecure: true
```
The `processors` section is used to process the incoming data before it is exported to the endpoints (like Jaeger). It 
is here where the batching configuration is set and also the heap settings for processing incoming data.
```
processors:
  memory_limiter:
    check_interval: 1s
    # maximum amount of memory (MB) targeted to be allocated by the process heap
    limit_mib: 2000
    # maximum spike expected between the measurements of memory usage (soft limit = limit_mib - spike_limit_mib)
    spike_limit_mib: 800
  batch:
    # number of spans/metrics/logs after which a batch will be sent regardless of the timeout
    send_batch_size: 5000
    # time duration after which a batch will be sent regardless of batch size
    timeout: 5s
    # upper limit of the batch sent to exporter
    send_batch_max_size: 0
```
Finally, the `service` section ties the `receivers`, `processors`, and `exporters` together. So the configuration below
sets a OTLP `receiver` in the OTEL Collector that will receive data from clients, process it using the `batch` and 
`memory_limiter` settings and then export to Jaeger.
```
service:
  extensions: [pprof, zpages, health_check]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch,memory_limiter]
      exporters: [jaeger]
```

### OTEL Jaeger Teardown

Once you are finished with the Kafka OTEL Collector Jaeger tracing demo, go in the `platform` folder and run this command:
```
./teardown.sh otel-jaeger
```
This will stop all the running docker containers for this project and cleanup the data volumes used by each in the
folder `platform/volumes`.

### Dynatrace Setup

Dynatrace has a [15-day free trial](https://www.dynatrace.com/trial) for its SaaS offering that is used for this demo. 
Sign up for the trial, which will create a Dynatrace instance for you accessible at a link that looks like
`https://<environment>.live.dynatrace.com/`. Set this url as the prefix of the variable `DYNATRACE_TRACES_URL` in the 
file `platform/.env`. So if your url is `https://abc12345.live.dynatrace.com/`, then you will want `DYNATRACE_TRACES_URL`
to look like this:
```
DYNATRACE_TRACES_URL=https://abc12345.live.dynatrace.com/api/v2/otlp/v1/traces
```
Open a web browser to your Dynatrace trial url `https://<environment>.live.dynatrace.com/`. On the left side there are
menu items and a menu filter. In the menu filter type `Access tokens`. Then click on the `Access tokens` menu item that 
appears below the filter. In this screen you will generate an access token by following the directions in the 
[Dynatrace documentation](https://www.dynatrace.com/support/help/extend-dynatrace/opentelemetry/opentelemetry-traces/opentelemetry-ingest/opent-java-auto#send).

1) First you click the button `Generate new token`.
2) Type a token name (such as `kafka`).
3) In the search field under the label `Select scopes from the table below` type `Ingest OpenTelemetry traces`.
4) `Ingest OpenTelemetry traces` should appear under the search field with a checkbox in front of it. Check the checkbox.
5) Click `Generate token` in the window that pops up
6) Copy the token value by clicking on the `Copy` button and paste it into the file `platform/.env` in the place of `<token>`.
```
DYNATRACE_API_TOKEN=<token>
```
7) Click the `Done` button to finish

Next, to start the Kafka Dynatrace tracing demo, go in the `platform` folder and run this command:
```
./setup.sh dynatrace
```
This demo will launch Zookeeper, Kafka brokers, Confluent Schema Registry, and the
`java-kafka-consumer`, `java-kafka-producer`, and `java-kafka-streams` applications. The Kafka applications are using 
the [OpenTelemetry Java agent](https://github.com/open-telemetry/opentelemetry-java-instrumentation)
to send trace data to Dynatrace. This agent uses the [Java Instrumentation API](https://www.baeldung.com/java-instrumentation)
to modify the bytecode of compiled Java applications to insert bytecode that sends trace data to an observability tool
based on the agent's configuration. The configuration can be seen in the file `platform/dynatrace.yml` in the services
`producer1`, `kstream1` and `consumer1`.

```
  producer1:
    image: com.mycompany/java-kafka-producer:0.0.1
    ...
    environment:
    ...
      OTEL_SERVICE_NAME: "producer1"
      OTEL_RESOURCE_ATTRIBUTES: "service.name=producer1,service.version=0.0.1,mytag=myvalue"
      OTEL_EXPORTER_OTLP_TRACES_ENDPOINT: ${DYNATRACE_TRACES_URL}
      OTEL_EXPORTER_OTLP_TRACES_PROTOCOL: "http/protobuf"
      OTEL_EXPORTER_OTLP_TRACES_HEADERS: "Authorization=Api-Token\ ${DYNATRACE_API_TOKEN}"
      OTEL_METRICS_EXPORTER: "none"
      OTEL_TRACES_SAMPLER: "traceidratio"
      OTEL_TRACES_SAMPLER_ARG: "0.5"
    ...
      JAVA_OPTS: >-
        ...
        -javaagent:/agents/opentelemetry-javaagent.jar
```

To see the tracing data, open up a browser and go to your Dynatrace trial url `https://<environment>.live.dynatrace.com/`.
On the left side there are menu items and a menu filter. In the menu filter type `Distributed traces`. Then click on 
the `Distributed traces` menu item that appears below the filter. Find a trace ID by looking at the `consumer1` logs by
executing `docker logs consumer1 -n 500 -f`. You should see something like this:
```
2022-09-08 18:47:06 - c.mycompany.kafka.consumer.Consumer - Consumed 1 records trace_id= span_id= trace_flags=
2022-09-08 18:47:06 - c.mycompany.kafka.consumer.Consumer - Record 2879451448152564224 headers: trace_id=543e3aa6d698422522b2072c338eddd5 span_id=e9a6a9250431c0c3 trace_flags=01
2022-09-08 18:47:06 - c.mycompany.kafka.consumer.Consumer - traceparent=00-543e3aa6d698422522b2072c338eddd5-8089b25b8289b085-01 trace_id=543e3aa6d698422522b2072c338eddd5 span_id=e9a6a9250431c0c3 trace_flags=01
2022-09-08 18:47:06 - c.mycompany.kafka.consumer.Consumer - 2879451448152564224: {firstName=Isis, lastName=Homenick, creditCardNumber=wqrvqbtxom, created=2022-03-31T04:35:28.862Z, id=2879451448152564224, updated=2021-12-16T01:57:52.633Z} trace_id=543e3aa6d698422522b2072c338eddd5 span_id=e9a6a9250431c0c3 trace_flags=01
```
Copy the trace ID from the logs (in this case `543e3aa6d698422522b2072c338eddd5`) and paste it into the Dynatrace 
distributed traces filter (labeled `Filter Requests`) by first selecting the `Request Property` `W3 trace ID` and pasting
the trace ID after it. You should see a trace below labeled `demo.customer send`. Click on that trace and you will see
all the spans of that trace.

* `demo.customer send (producer1)` - the `producer1` application sending the message to the topic `demo.customer`
* `demo.customer process (kstream1)` - the `kstream1` application receiving the message from the topic `demo.customer`
* `demo.transform.customer send (kstream1)` - the `kstream1` application sending the message to the topic `demo.transform.customer`
* `demo.transform.customer process (consumer1)` - the `consumer1` application receiving the message from the topic `demo.transform.customer`

You can also clear the `Filter Requests` and select a time period to see all traces at the top (select `Last 30 minutes`
for example).

### Dynatrace Teardown

Once you are finished with the Kafka Dynatrace tracing demo, go in the `platform` folder and run this command:
```
./teardown.sh dynatrace
```
This will stop all the running docker containers for this project and cleanup the data volumes used by each in the
folder `platform/volumes`.

### OTEL Dynatrace Setup

To start the Kafka OTEL Collector Dynatrace tracing demo, go in the `platform` folder and run this command:
```
./setup.sh otel-dynatrace
```
In addition to launching Zookeeper, Kafka brokers, Confluent Schema Registry, Kafka Connect workers, and the
`java-kafka-consumer`, `java-kafka-producer`, and `java-kafka-streams` applications, this demo will also launch
the [OTEL Collector](https://github.com/open-telemetry/opentelemetry-collector)
for metrics collection. The Kafka applications are using the [OpenTelemetry Java agent](https://github.com/open-telemetry/opentelemetry-java-instrumentation)
to send trace data to the OTEL Collector which forwards the data to Dynatrace. This agent uses the [Java Instrumentation API](https://www.baeldung.com/java-instrumentation)
to modify the bytecode of compiled Java applications to insert bytecode that sends trace data to an observability tool
based on the agent's configuration. The configuration can be seen in the file `platform/jaeger.yml` in the services
`producer1`, `kstream1` and `consumer1`. The advantage of using the OTEL Collector is that it can collect trace data sent
from several clients and forward it to the destination telemetry system in batches. This is especially advantageous when
the end telemetry system is in the cloud. The OTEL Collector should be deployed near the clients so network latency is
minimal.

The OTEL Collector configuration is defined in the file `platform/otel/otel-collector-dynatrace.yml`. The `receivers`
section defines how the OTEL Collector will receive data from the clients.
```
receivers:
  otlp:
    protocols:
      grpc:
      http:
```
The `exporters` section defines the endpoints where the OTEL Collector is sending data. In this case, one endpoint is
defined for Dynatrace (cloud).
```
exporters:
  otlphttp:
    endpoint: "https://<environment>.live.dynatrace.com/api/v2/otlp"
    headers:
      Authorization: "Api-Token <token>"
```
In the `endpoint` value you will need to replace `<environment>` with the environment for
your Dynatrace instance. You will also need to create an API token and replace `<token>` with your token value in the
`Authorization` header value. To learn how to create an API token in Dynatrace, see the [Dynatrace Setup](#dynatrace-setup) 
section of this README. Here is an example:
```
exporters:
  otlphttp:
    endpoint: "https://abc12345.live.dynatrace.com/api/v2/otlp"
    headers:
      Authorization: "Api-Token dt9c99.1133MHGYTU1DZYYR1BRYBZXA.GGEXZ31DDYGUIQEDRMNDRWR1W7J3J44TRWXUBJ5QP4Y6OLHK4A3CMSHTAQRTL199"
```
The `processors` section is used to process the incoming data before it is exported to the endpoints (like Dynatrace). It
is here where the batching configuration is set and also the heap settings for processing incoming data.
```
processors:
  memory_limiter:
    check_interval: 1s
    # maximum amount of memory (MB) targeted to be allocated by the process heap
    limit_mib: 2000
    # maximum spike expected between the measurements of memory usage (soft limit = limit_mib - spike_limit_mib)
    spike_limit_mib: 800
  batch:
    # number of spans/metrics/logs after which a batch will be sent regardless of the timeout
    send_batch_size: 5000
    # time duration after which a batch will be sent regardless of batch size
    timeout: 5s
    # upper limit of the batch sent to exporter
    send_batch_max_size: 0
```
Finally, the `service` section ties the `receivers`, `processors`, and `exporters` together. So the configuration below
sets a OTLP `receiver` in the OTEL Collector that will receive data from clients, process it using the `batch` and
`memory_limiter` settings and then export to Dynatrace.
```
service:
  extensions: [pprof, zpages, health_check]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch,memory_limiter]
      exporters: [otlphttp]
```

### OTEL Dynatrace Teardown

Once you are finished with the Kafka OTEL Collector Dynatrace tracing demo, go in the `platform` folder and run this command:
```
./teardown.sh otel-dynatrace
```
This will stop all the running docker containers for this project and cleanup the data volumes used by each in the
folder `platform/volumes`.