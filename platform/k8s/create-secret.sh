#!/bin/bash

[[ -z "$1" ]] && { echo "Namespace not specified" ; exit 1; }
NAMESPACE=$1

[[ -z "$2" ]] && { echo "Secret name not specified" ; exit 1; }
NAME=$2

[[ -z "$3" ]] && { echo "Username not specified" ; exit 1; }
USERNAME=$3

[[ -z "$4" ]] && { echo "Password not specified" ; exit 1; }
PASSWORD=$4

kubectl -n ${NAMESPACE} create secret generic $NAME --from-literal=username=${USERNAME} \
--from-literal=password=${PASSWORD}