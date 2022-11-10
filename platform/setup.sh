#!/bin/bash

START=$SECONDS

# env from user input
ENVS=("jaeger" "otel-jaeger" "dynatrace" "otel-dynatrace" "otel-dynatrace-ccloud" "honeycomb-ccloud")
[[ -z "$1" ]] && { echo "Environment (${ENVS[@]}) not specified" ; exit 1; }
[[ ! " ${ENVS[@]} " =~ " $1 " ]] && { echo "Invalid environment $1 specified. Valid envs are (${ENVS[@]})." ; exit 1; }
ENV=$1

# cleanup volumes
echo ""
echo "******************************************************************"
echo "Cleaning up volumes"
echo "******************************************************************"
echo ""
./cleanup.sh

# launch docker containers
echo ""
echo "******************************************************************"
echo "Starting docker containers"
echo "******************************************************************"
echo ""
docker-compose -f $ENV.yml up -d client connect1 postgres

DURATION=$(( SECONDS - START ))
echo ""
echo "Finished setup of environment $ENV in $DURATION secs"
exit 0