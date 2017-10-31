#!/bin/bash

echo ">>> Creating an api that simply echoes the request using mockbin, using a 'catch-all' setup with the `uris` field set to '/'..."
curl -i -X POST \
  --url http://localhost:8001/apis/ \
  --data 'name=mockbin' \
  --data 'upstream_url=http://mockbin.org/request' \
  --data 'uris=/'

echo -e "\n"
echo -e ">>> Adding the custom plugin, to our new api..."
curl -i -X POST \
  --url http://localhost:8001/apis/mockbin/plugins/ \
  --data 'name=keystone'
  # --data "config.foo=bar"

curl -i http://localhost:8000