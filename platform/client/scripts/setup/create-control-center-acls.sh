#!/bin/bash

echo "Creating general ACLs for Control Center"

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

PRINCIPALS=("c3")

for PRINCIPAL in "${PRINCIPALS[@]}"
do

  echo "Setting acls for all topics"
  kafka-acls --bootstrap-server $BROKER_URL --command-config $KAFKA_CONFIG --add --allow-principal "User:$PRINCIPAL" \
      --operation ALL --topic '*' --group '*' #> /dev/null 2>&1 || echo "Failed"    

  if [[ $ACL == "true" ]]; then
  	sr-acl-cli --config $SCHEMA_CONFIG --add --principal $ADMIN_PRINCIPAL --operation GLOBAL_READ
    sr-acl-cli --config $SCHEMA_CONFIG --add --principal $ADMIN_PRINCIPAL --operation SUBJECT_READ --subject '*'
    sr-acl-cli --config $SCHEMA_CONFIG --add --principal $ADMIN_PRINCIPAL --operation SUBJECT_WRITE --subject '*'
  fi
done

echo "Created general ACLs for Control Center"