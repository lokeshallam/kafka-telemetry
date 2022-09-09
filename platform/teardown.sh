#!/bin/bash

START=$SECONDS

# env from user input
ENVS=("jaeger" "otel-jaeger" "dynatrace" "otel-dynatrace")
[[ -z "$1" ]] && { echo "Environment (${ENVS[@]}) not specified" ; exit 1; }
[[ ! " ${ENVS[@]} " =~ " $1 " ]] && { echo "Invalid environment $1 specified. Valid envs are (${ENVS[@]})." ; exit 1; }
ENV=$1

# launch docker containers
echo ""
echo "******************************************************************"
echo "Stopping docker containers"
echo "******************************************************************"
echo ""
docker-compose -f $ENV.yml down

# cleanup volumes
echo ""
echo "******************************************************************"
echo "Cleaning up volumes"
echo "******************************************************************"
echo ""
./cleanup.sh

DURATION=$(( SECONDS - START ))
echo ""
echo "Finished tearing down environment $ENV in $DURATION secs"
exit 0