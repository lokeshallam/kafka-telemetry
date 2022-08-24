#!/bin/bash

BASE=$(dirname "$0")
cd ${BASE}
. ../env.sh $1
[ $? -eq 1 ] && echo "Could not setup environment variables" && exit

[[ -z "$2" ]] && { echo "Topic name not specified" ; exit 1; }
TOPIC=$2

printf -v DATE '%(%Y-%m-%dT00:00:00)T' -1

ACCESS_KEY=""
SECRET_KEY=""

# create post data for metrics API query
POST_DATA=$(cat <<EOF
{
    "aggregations": [
        {
            "metric": "io.confluent.kafka.server/retained_bytes"
        }
    ],
    "filter": {
        "op": "AND",
        "filters": [
            {
                 "field": "metric.topic",
                 "op": "EQ",
                 "value": "$TOPIC"
            },
            {
                "field": "resource.kafka.id",
                "op": "EQ",
                "value": "$CLUSTER"
            }
        ]
    },
    "granularity": "PT1M",
    "group_by": [
        "metric.topic"
    ],
    "intervals": [
        "$DATE-05:00/P0Y0M0DT2H0M0S"
    ],
    "limit": 25
}
EOF
)

# execute query against metrics API
curl -X POST -H "Content-Type: application/json" --user "$ACCESS_KEY:$SECRET_KEY" --data "$POST_DATA" https://api.telemetry.confluent.cloud/v2/metrics/cloud/query
echo ""
