#!/bin/bash

source k8s.properties

echo "Tearing down deployments in namespace ${namespace}"
kubectl -n ${namespace} delete -f deployments.yml
echo "Deleting configmaps in namespace ${namespace}"
kubectl -n ${namespace} delete configmap kafka-config
echo "Deleting secrets in namespace ${namespace}"
kubectl -n ${namespace} delete secret kafka-credentials
kubectl -n ${namespace} delete secret schema-credentials
kubectl -n ${namespace} delete secret otel-collector-config
echo "Teardown in namespace ${namespace} completed"