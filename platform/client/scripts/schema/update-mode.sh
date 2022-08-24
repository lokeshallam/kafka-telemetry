#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Mode (IMPORT, READONLY, READWRITE) not specified" ; exit 1; }
MODE=$2

if [[ $ACL == "true" ]]; then
  curl -X PUT --cert $KEYSTORE_DIR/kafka1.${DOMAIN}_cert.pem --key $KEYSTORE_DIR/kafka1.${DOMAIN}_key.pem --cacert $KEYSTORE_DIR/intermediate.crt \
  --pass $KEYSTORE_PASSWORD --data "{\"mode\":\"$MODE\"}" -H "Content-Type:application/vnd.schemaregistry.v1+json" $SCHEMA_URL/mode
else
  curl -k -u admin:admin-secret -X PUT --data "{\"mode\":\"$MODE\"}" -H "Content-Type:application/vnd.schemaregistry.v1+json" $SCHEMA_URL/mode
fi
echo ""