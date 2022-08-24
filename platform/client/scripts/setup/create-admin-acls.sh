#!/bin/bash

echo "Creating general ACLs for admin"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

PRINCIPALS="1"
if [[ "$2" ]]; then
  PRINCIPALS="$2"
fi

for ((i=1; i<=$PRINCIPALS; i++))
do
  ADMIN_PRINCIPAL="kafka$i"
  if [[ $ACL == "true" ]]; then
    sr-acl-cli --config $SCHEMA_CONFIG --add --principal $ADMIN_PRINCIPAL --operation GLOBAL_READ
    sr-acl-cli --config $SCHEMA_CONFIG --add --principal $ADMIN_PRINCIPAL --operation GLOBAL_COMPATIBILITY_READ
    sr-acl-cli --config $SCHEMA_CONFIG --add --principal $ADMIN_PRINCIPAL --operation GLOBAL_COMPATIBILITY_WRITE
    sr-acl-cli --config $SCHEMA_CONFIG --add --principal $ADMIN_PRINCIPAL --operation SUBJECT_READ --subject '*'
    sr-acl-cli --config $SCHEMA_CONFIG --add --principal $ADMIN_PRINCIPAL --operation SUBJECT_WRITE --subject '*'
    sr-acl-cli --config $SCHEMA_CONFIG --add --principal $ADMIN_PRINCIPAL --operation SUBJECT_DELETE --subject '*'
  fi
done

echo "Created general ACLs for admin"
cd ../