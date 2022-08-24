#!/bin/bash
echo "Creating schema from file"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Subject not specified" ; exit 1; }
SUBJECT=$2

[[ -z "$3" ]] && { echo "Filename not specified" ; exit 1; }
FILENAME=$3

JSON=$(cat $FILENAME)
JSON=${JSON//$'\n'/}
JSON=${JSON//\"/\\\"}  
echo $JSON

if [[ $ACL == "true" ]]; then
  curl -X POST --cert $KEYSTORE_DIR/kafka1.${DOMAIN}_cert.pem --key $KEYSTORE_DIR/kafka1.${DOMAIN}_key.pem --cacert $KEYSTORE_DIR/intermediate.crt \
  --pass $KEYSTORE_PASSWORD -H "Content-Type:application/vnd.schemaregistry.v1+json" --data "{\"schema\": \"$JSON\"}" $SCHEMA_URL/subjects/$SUBJECT/versions
else
  curl -k -u admin:admin-secret -X POST -H "Content-Type:application/vnd.schemaregistry.v1+json" --data "{\"schema\": \"$JSON\"}" $SCHEMA_URL/subjects/$SUBJECT/versions
fi
echo ""