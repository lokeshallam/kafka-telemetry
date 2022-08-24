#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

if [[ $ACL == "true" ]]; then
  curl -X GET --cert ${KEYSTORE_DIR}/kafka1.${DOMAIN}_cert.pem --key ${KEYSTORE_DIR}/kafka1.${DOMAIN}_key.pem --cacert ${KEYSTORE_DIR}/intermediate.crt \
  --pass ${KEYSTORE_PASSWORD} ${SCHEMA_URL}/mode
else
  curl -k -u admin:admin-secret -X GET ${SCHEMA_URL}/mode
fi
echo ""