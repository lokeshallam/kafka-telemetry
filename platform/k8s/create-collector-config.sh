#!/bin/bash

[[ -z "$1" ]] && { echo "Namespace not specified" ; exit 1; }
NAMESPACE=$1

NAME="otel-collector-config"
FILENAME="config.yml"
FILEPATH="../otel/otel-collector-dynatrace.yml"

kubectl -n ${NAMESPACE} create secret generic "${NAME}" --from-file=${FILENAME}=${FILEPATH}