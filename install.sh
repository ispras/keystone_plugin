#!/usr/bin/env bash

if  test "$#" -ne  2; then

echo "<name> and <password> required"

else

luarocks make kong-plugin-keystone-0.1.0-1.rockspec
if [ $? -eq 0 ]; then

echo ">>> Save admin_creds in /etc/kong/admin_creds"
echo "$1
$2" > /etc/kong/admin_creds
echo ">>> Copy customized configuration file"
cp ./kong.conf /etc/kong/kong.conf
echo ">>> Copy policy file"
cp ./kong/plugins/keystone/policy_keystone.json /etc/kong/policy_keystone.json
echo ">>> Fill database, need some time"
kong migrations up -c /etc/kong/kong.conf
if [ $? -eq 0 ]; then

kong restart -c /etc/kong/kong.conf
if [ $? -eq 0 ]; then

echo ">>> Configuration"
#lua update_keystone_conf.lua
curl -i -X POST   --url http://localhost:8001/apis/   --data 'name=mockbin'   --data 'upstream_url=http://mockbin.org/request'   --data 'uris=/'
curl -i -X POST   --url http://localhost:8001/apis/mockbin/plugins/   --data 'name=keystone'

kong stop

fi
fi
fi
fi