#!/bin/bash

# load variables from k8s.properties file
source k8s.properties

# create kafka configmap
echo "Creating Confluent Cloud configmap in namespace ${namespace}"
kubectl -n ${namespace} create configmap kafka-config --from-literal=bootstrap-url=${ccloud_bootstrap_url} \
--from-literal=schema-registry-url=${schema_registry_url}

# create kafka credentials secret
echo "Creating Confluent Cloud secret in namespace ${namespace}"
kubectl -n ${namespace} create secret generic kafka-credentials --from-literal=username=${ccloud_api_key} \
--from-literal=password=${ccloud_api_secret}

# create schema registry credentials secret
echo "Creating Schema Registry secret in namespace ${namespace}"
kubectl -n ${namespace} create secret generic schema-credentials --from-literal=username=${schema_registry_api_key} \
--from-literal=password=${schema_registry_api_secret}

# create the OTEL Collector config file
cat >otel-collector-config.yml <<EOF
receivers:
  otlp:
    protocols:
      grpc:
      http:

exporters:
  otlphttp:
    endpoint: "${dynatrace_trace_url}"
    headers:
      Authorization: "Api-Token ${dynatrace_api_token}"

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

extensions:
  health_check:
  pprof:
    endpoint: :1888
  zpages:
    endpoint: :55679

service:
  extensions: [pprof, zpages, health_check]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch,memory_limiter]
      exporters: [otlphttp]
EOF

# create the OTEL collector config file as a secret
echo "Creating OTEL Collector config file in namespace ${namespace}"
kubectl -n ${namespace} create secret generic otel-collector-config --from-file=config.yml=otel-collector-config.yml
# cleanup OTEL collector config file now that its uploaded as a secret into k8s
rm -rf otel-collector-config.yml

# create deployments and services from k8s resources file
echo "Setting up deployments in namespace ${namespace}"
kubectl -n ${namespace} apply -f deployments.yml

echo "Setup in namespace ${namespace} completed"
