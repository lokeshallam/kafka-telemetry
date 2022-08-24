#!/bin/bash

[[ -z "$1" ]] && { echo "MDS URL not specified" ; exit 1; }
MDS_URL="$1"

[[ -z "$2" ]] && { echo "Username not specified" ; exit 1; }
USERNAME="$2"

TOKEN=$(curl -k -u $USERNAME $MDS_URL/security/1.0/authenticate) #| sed -n "s/^\"auth_token\": \"\(.*\)^\"$/\1/p")
echo $TOKEN

curl -k -H "Authorization: Bearer $TOKEN" $MDS_URL/kafka/v3/cluster