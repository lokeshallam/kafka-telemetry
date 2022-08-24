#!/bin/bash

curl -k -X DELETE -u datagen:datagen-secret -H "Content-Type:application/vnd.schemaregistry.v1+json" https://localhost:8081/subjects/env.app.person-value
