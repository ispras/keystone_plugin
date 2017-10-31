#!/bin/bash

HOME=/home/valerius/git

cd $HOME

echo ">>> Copying necessary files..."
cp -a keystone_plugin/kong/plugins/keystone kong-vagrant/kong/kong/plugins
cp -a keystone_plugin/kong/plugins/keystone kong-vagrant/kong-plugin/kong/plugins
cp keystone_plugin/sha512.lua kong-vagrant/kong-plugin/sha512.lua
cp keystone_plugin//uuid4.lua kong-vagrant/kong-plugin/uuid4.lua
cp keystone_plugin/kong-plugin-keystone-0.1.0-1.rockspec kong-vagrant/kong-plugin/kong-plugin-keystone-0.1.0-1.rockspec
cp keystone_plugin/kong-0.11.0-0.rockspec kong-vagrant/kong/kong-0.11.0-0.rockspec
cp keystone_plugin/kong.conf kong-vagrant/kong-plugin/kong.conf 
cp keystone_plugin/keystone.sh kong-vagrant/kong-plugin/keystone.sh 

echo ">>> Vagrant up..."
cd kong-vagrant
vagrant up
vagrant ssh