#!/bin/bash

echo ">>> Copying configuration file..."
sudo cp /kong-plugin/kong.conf /etc/kong/kong.conf
echo ">>> Setting up dev environment..."
cd /kong
make dev
echo ">>> export KONG_CUSTOM_PLUGINS=keystone"
export KONG_CUSTOM_PLUGINS=keystone
echo ">>> Updating database schema..."
kong migrations up
echo ">>> Starting kong..."
kong start -c /etc/kong/kong.conf