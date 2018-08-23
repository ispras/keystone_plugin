#!/usr/bin/env bash

keystone_ep="http://localhost:8000/v3/"
init_ep="http://localhost:8000/v3"

curl -i -X POST --url $init_ep
token=$(curl -i  -H "Content-Type: application/json" -X POST --url $keystone_ep'auth/tokens' -d '{
    "auth" : {
        "identity" : {
            "methods" : [ "password" ],
            "password" : {
                "user" : {
                    "name" : "'"$1"'",
                    "domain" : {
                        "name" : "Default"
                    },
                    "password" : "'"$2"'"
                }
            }
        }
    }
}' | grep X-Subject-Token| awk {'print $2'})

curl -H "Content-Type: application/json" -H "X-Auth-Token: "$token -X POST --url $keystone_ep'regions' -d '{
    "region": {
        "description": "My subregion",
        "id": "RegionOne"
    }
}'
identity_service_id=$(curl -H "Content-Type: application/json" -H "X-Auth-Token: "$token -X POST --url $keystone_ep'services' -d '{
    "service": {
        "type": "identity",
        "name": "keystone",
        "description": "identity service",
        "enabled": true
    }
}' | jq -r '.services.id')
curl -H "Content-Type: application/json" -H "X-Auth-Token: "$token -X POST --url $keystone_ep'endpoints' -d '{
    "endpoint": {
        "interface": "internal",
        "region_id": "RegionOne",
        "url": "'$keystone_ep'",
        "service_id": "'$identity_service_id'"
    }
}'
curl -H "Content-Type: application/json" -H "X-Auth-Token: "$token -X POST --url $keystone_ep'endpoints' -d '{
    "endpoint": {
        "interface": "public",
        "region_id": "RegionOne",
        "url": "'$keystone_ep'",
        "service_id": "'$identity_service_id'"
    }
}'
curl -H "Content-Type: application/json" -H "X-Auth-Token: "$token -X POST --url $keystone_ep'endpoints' -d '{
    "endpoint": {
        "interface": "admin",
        "region_id": "RegionOne",
        "url": "'$keystone_ep'",
        "service_id": "'$identity_service_id'"
    }
}'