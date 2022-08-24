#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

if [[ $ACL == "true" ]]; then
  IN="$(curl -X GET --cert ${KEYSTORE_DIR}/kafka1.${DOMAIN}_cert.pem --key ${KEYSTORE_DIR}/kafka1.${DOMAIN}_key.pem --cacert ${KEYSTORE_DIR}/intermediate.crt --pass ${KEYSTORE_PASSWORD} ${SCHEMA_URL}/subjects | tr -d '[]"')"
else
  IN="$(curl -k -X GET ${SCHEMA_URL}/subjects | tr -d '[]"')"
fi
echo "$IN"

subjects=$(echo $IN | tr "," "\n")
for subject in $subjects
do
    printf "deleting schema ${subject}\n"
    if [[ $ACL == "true" ]]; then
      curl -X DELETE --cert ${KEYSTORE_DIR}/kafka1.${DOMAIN}_cert.pem --key ${KEYSTORE_DIR}/kafka1.${DOMAIN}_key.pem --cacert ${KEYSTORE_DIR}/intermediate.crt \
      --pass ${KEYSTORE_PASSWORD} ${SCHEMA_URL}/subjects/${subject}
    else
      curl -k -u admin:admin-secret -X DELETE ${SCHEMA_URL}/subjects/${subject}
    fi
    printf "\n"
done