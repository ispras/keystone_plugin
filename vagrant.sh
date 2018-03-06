#!/bin/bash

HOME=/home/lenaaxenova/virtualbox/keystone/

cd $HOME

echo ">>> Copying necessary files..."
cp -a /home/lenaaxenova/PycharmProjects/keystonev3/keystone_plugin/kong/plugins/keystone kong-vagrant/kong/kong/plugins
cp -a /home/lenaaxenova/PycharmProjects/keystonev3/keystone_plugin/kong/plugins/keystone kong-vagrant/kong-plugin/kong/plugins
cp /home/lenaaxenova/PycharmProjects/keystonev3/keystone_plugin/sha512.lua kong-vagrant/kong-plugin/sha512.lua
cp /home/lenaaxenova/PycharmProjects/keystonev3/keystone_plugin/uuid4.lua kong-vagrant/kong-plugin/uuid4.lua
cp /home/lenaaxenova/PycharmProjects/keystonev3/keystone_plugin/kong-plugin-keystone-0.1.0-1.rockspec kong-vagrant/kong-plugin/kong-plugin-keystone-0.1.0-1.rockspec
cp /home/lenaaxenova/PycharmProjects/keystonev3/keystone_plugin/kong-0.11.0-0.rockspec kong-vagrant/kong/kong-0.11.0-0.rockspec
cp /home/lenaaxenova/PycharmProjects/keystonev3/keystone_plugin/kong.conf kong-vagrant/kong-plugin/kong.conf 
cp /home/lenaaxenova/PycharmProjects/keystonev3/keystone_plugin/keystone.sh kong-vagrant/kong-plugin/keystone.sh 
cp /home/lenaaxenova/PycharmProjects/keystonev3/keystone_plugin/api.sh kong-vagrant/kong-plugin/api.sh 
 
echo ">>> Vagrant up..."
cd kong-vagrant
sudo vagrant up
sudo vagrant ssh
