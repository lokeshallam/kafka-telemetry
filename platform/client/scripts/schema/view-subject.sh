#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Subject not specified" ; exit 1; }
SUBJECT=$2

[[ -z "$3" ]] && { echo "Version not specified" ; exit 1; }
VERSION=$3

if [[ $ACL == "true" ]]; then
  curl -X GET --cert ${KEYSTORE_DIR}/kafka1.${DOMAIN}_cert.pem --key ${KEYSTORE_DIR}/kafka1.${DOMAIN}_key.pem --cacert ${KEYSTORE_DIR}/intermediate.crt \
  --pass ${KEYSTORE_PASSWORD} ${SCHEMA_URL}/subjects/${SUBJECT}/versions/${VERSION}
else
  curl -k -u admin:admin-secret -X GET ${SCHEMA_URL}/subjects/${SUBJECT}/versions/${VERSION}
fi
echo ""