#!/usr/bin/env bash

sudo luarocks make kong-plugin-keystone-0.1.0-1.rockspec
echo ">>> Configuration"
#lua update_keystone_conf.lua
curl -i -X POST   --url http://localhost:8001/apis/   --data 'name=mockbin'   --data 'upstream_url=http://mockbin.org/request'   --data 'uris=/'
curl -i -X POST   --url http://localhost:8001/apis/mockbin/plugins/   --data 'name=keystone'
curl -i -X POST   --url http://localhost:8001/v3/
echo ">>> Save admin_creds in /etc/kong/admin_creps"
sudo echo "$1
$2" > /etc/kong/admin_creds
echo ">>> Copy customized configuration file"
sudo cp ./kong.conf /etc/kong/kong.conf
echo ">>> Copy policy file"
sudo cp ./kong/plugins/keystone/policy_keystone.json /etc/kong/policy_keystone.json
echo ">>> Fill database, need some time"
sudo kong migrations up -c /etc/kong/kong.conf
sudo kong start -c /etc/kong/kong.conf
