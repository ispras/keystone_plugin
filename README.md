# Keystone plugin for Kong

This instruction will explain how to prepare the environment for developing Kong plugins and how to install, run and test the Keystone plugin. 

## **Step 0: Cassandra**
 
First, you need to install [Cassandra](http://cassandra.apache.org/). [Installation](http://cassandra.apache.org/download/) from Debian packages:

~~~sh
$ echo "deb http://www.apache.org/dist/cassandra/debian 311x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
$ curl https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -
$ sudo apt-get update
$ sudo apt-get install cassandra
~~~

If errors appear try:

~~~sh
$ sudo apt-get install libssl1.0.0
~~~

Start cassandra:

~~~sh
$ sudo service cassandra start
~~~~

Now, if all goes well, you Cassandra database.

## **Step 1: Kong**

[Kong](https://getkong.org/) is an open-source API proxy based on [NGINX](http://nginx.org/), which aims to «secure, manage and extend APIs and Microservices» thanks to a plugins oriented architecture.
 
Now you can install [Kong](https://konghq.com/install/) for [ubuntu](https://getkong.org/install/ubuntu/). Choose your version and download package.

~~~sh
$ sudo apt-get update
$ sudo apt-get install openssl libpcre3 procps perl
$ sudo dpkg -i kong-community-edition-0.13.1.*.deb
~~~

If you don’t have any problems, you can start Kong with this command:

~~~sh
$ sudo kong start
~~~
 
Kong is now started and is available on the default ports:

* 8000 Proxy port
* 8443 SSL Proxy port
* 8001 Admin API
* 8444 SSL Admin API
 
To verify Kong is running successfully, execute the following command:

~~~sh
$ curl http://localhost:8001
~~~
   
You should receive a **JSON** response:

~~~javascript
{
  "tagline": "Welcome to Kong",
  "version": "x.x.x",
  "hostname": "precise64",
  "lua_version": "LuaJIT 2.1.0-alpha",
  "plugins": {
    "enabled_in_cluster": {},
    "available_on_server": [
      ...
    ]
  }
}
~~~

For stopping the Kong instance use following command:

~~~sh
$ sudo kong stop
~~~ 

## **Step 2: Keystone plugin**

The **keystone-plugin** executes some functions, which exist in [Keystone](https://docs.openstack.org/keystone/latest/), the [OpenStack](https://docs.openstack.org/) Identity Service. Keystone is an OpenStack service that provides API client authentication, service discovery, and distributed multi-tenant authorization by implementing [OpenStack’s Identity API](https://developer.openstack.org/api-ref/identity/v3/).

Code of the project can be found [here](https://github.com/ispras/keystone_plugin).

So, let's clone this project:

~~~sh
$ cd KEY_DIR
$ git clone https://github.com/ispras/keystone_plugin.git
$ cd keystone_plugin
~~~

Now we will integrate this plugin in the local kong project.

Also you should modify rockspecs files adding information about keystone-plugin and required lua-modules. You can do it by copying rockspecs files from keystone-plugin project to it:

~~~sh
$ cp ~/keystone_plugin/kong-plugin-keystone-0.1.0-1.rockspec ~/kong-vagrant/kong-plugin/kong-plugin-keystone-0.1.0-1.rockspec
$ cp ~/keystone_plugin/kong-0.10.3-0.rockspec ~/kong-vagrant/kong/kong-0.10.3-0.rockspec
~~~

Copy to **~/kong-vagrant/kong-plugin** customized configuration file, which opts [Cassandra DB](https://cassandra.apache.org/) as data store and keystone-plugin as custom plugin:

~~~sh
$ cp ~/keystone_plugin/kong.conf ~/kong-vagrant/kong-plugin/kong.conf 
~~~ 

Now it's time to build the VM and ssh into it, but first make certain that all vagrant VM are destroyed:

~~~sh 
$ cd ~/kong-vagrant
$ sudo vagrant up
$ sudo vagrant ssh 
~~~

Copy your configuration file into **/etc/kong/kong.conf** (do it inside the VM):

~~~sh
$ sudo cp /kong-plugin/kong.conf /etc/kong/kong.conf
~~~

Let's start kong and specify our configuration file:

~~~sh
$ cd /kong
$ sudo make dev
$ export KONG_CUSTOM_PLUGINS=keystone
$ bin/kong start -c /etc/kong/kong.conf
~~~

Make sure, that kong has started without any problems:

~~~sh
$ curl http://localhost:8001
~~~

 If you have some problems and the code status of the response isn't 200 look at logs, you can find them in VM directory **/usr/local/kong/logs **and errors are described in file **error.log**:

 In case you don't have any problems let's add API and keystone as custom plugin from the host machine:
 
~~~sh
$  curl -i -X POST   --url http://localhost:8001/apis/   --data 'name=mockbin'   --data 'upstream_url=http://mockbin.org/request'   --data 'uris=/'
$  curl -i -X POST   --url http://localhost:8001/apis/mockbin/plugins/   --data 'name=keystone'
~~~

Then try to check the Admin host 8001 again:

~~~sh
$ curl http://localhost:8001
~~~

You should receive a response like this:

~~~sh
HTTP/1.1 200 OK
Date: Tue, 04 Jul 2017 13:20:41 GMT
Content-Type: application/json; charset=utf-8
Transfer-Encoding: chunked
Connection: keep-alive
Access-Control-Allow-Origin: *
Server: kong/0.10.3

{..."plugins":{"enabled_in_cluster":["keystone"],"available_on_server":{"syslog":true,"ldap-auth":true,"rate-limiting":true,"correlation-id":true,"jwt":true,"request-termination":true,"galileo":true,"runscope":true,"request-transformer":true,"http-log":true,"loggly":true,"response-transformer":true,"basic-auth":true,"tcp-log":true,"hmac-auth":true,"oauth2":true,"acl":true,"bot-detection":true,"udp-log":true,"cors":true,"file-log":true,"ip-restriction":true,"datadog":true,"request-size-limiting":true,"keystone":true,"aws-lambda":true,"statsd":true,"response-ratelimiting":true,"key-auth":true}}}
~~~

Pay attention to the presence of the following lines:

* **"custom_plugins":["keystone"]**
* **"plugins":{"enabled_in_cluster":["keystone"] ...}**
* **"available_on_server":{..., "keystone":true, ...}**

If you have found those lines, keystone-plugin is running and is enabled. So you can try to check some functions provided by this plugin. First let's call the simplest GET-method, that shows us information about keystone version:

~~~sh
$ curl -i http://localhost:8001/v2.0/
~~~

The response must look like this:

~~~sh
HTTP/1.1 200 OK
Date: Tue, 04 Jul 2017 13:20:42 GMT
Content-Type: application/json; charset=utf-8
Transfer-Encoding: chunked
Connection: keep-alive
Access-Control-Allow-Origin: *
Server: kong/0.10.3
Vary: X-Auth-Token
x-openstack-request-id: 7E7BEFE2-D0A3-43B3-A584-1CEBC3B4C34B

{"version":{"updated":"2014-04-17T00:00:00Z","id":"v2.0","status":"stable","media-types":[{"base":"application\/json","type":"application\/vnd.openstack.identity-v2.0+json"}],"links":[{"href":"http:\/\/127.0.0.1:35357\/v2.0\/","rel":"self"},{"href":"http:\/\/docs.openstack.org\/","rel":"describedby","type":"text\/html"}]}}
~~~

For manual testing of other methods you can use some rested extension for your browser. For example if you have Mozila browser the REST-extension you can find here:

![](https://vfc.cc/0af826414e4fb04054ec5ecfc89f4c1f) 

![](https://vfc.cc/3dc2f4b98f4017cd82b9763a389ce9b4) 

So let's create tenant entity with name "admin". It will be POST-method via link http://localhost:8001/v2.0/tenants with following message in JSON format:

~~~javascript
{ 
    "tenant": 
        {
            "name": "admin"
        }
}
~~~

So in Mozila REST-extension it will look like this:

![](https://vfc.cc/d64f0da154546e64030a8f1b05d25b61)

Create user entity with name "admin" that will belong to created tenant. It will be POST-method via link http://localhost:8001/v2.0/users with following message in JSON format:

~~~javascript
{ 
    { 
    "user": 
        {
            "name": "admin",
             "tenantId": "EDD52ED8-B362-40AA-91A6-26596DAF5017",
             "password": "tester",
             "email": "some@email.com"
        }
    }
}
~~~

In field "tenantId" should be ID of the admin-tenant that we have created yet. This ID you have received in the response on that query. 

In Mozila REST-extension it will look like this:

![](https://vfc.cc/29c9b77c2f108e1832baa910f9942b36)

You can test the other GET-method that shows information of a user by his ID via link http://localhost:8001/v2.0/users/:user_id. Replace "user_id" with ID of the admin-user, that we have created. This ID you have received in the response on that query. 

Now you can receive a token for this user. Execute POST-method via link http://localhost:8001/v2.0/tokens with following message in JSON format:

~~~javascript
{
    "auth": {
        "passwordCredentials": {
            "username": "admin", 
            "password": "tester"
        },
        "tenantName": "admin"
    }
}
~~~

In Mozila REST-extension it will look like this:

![](https://vfc.cc/b7283005662ed5d990229b25bf12da22)

Also you can test two DELETE-methods: 

* http://localhost:8001/v2.0/tenants/:tenant_id
* http://localhost:8001/v2.0/users/:user_id

These queries will delete entities by their ID.


## **Instruction for running Keystone plugin on Ubuntu**

~~~sh
http://cassandra.apache.org/download/ :
        echo "deb http://www.apache.org/dist/cassandra/debian 311x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
        curl https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -
        sudo apt-get update
        sudo apt-get install cassandra
        sudo service cassandra start
        sudo apt-get install libssl1.0.0
https://getkong.org/install/ubuntu/
        git clone https://github.com/lenaaxenova/keystone_plugin.git
        cd keystone_plugin
        git checkout v3
https://getkong.org/docs/0.11.x/plugin-development/distribution/ :
        sudo luarocks make kong-plugin-keystone-0.1.0-1.rockspec
        sudo cp ./kong.conf /etc/kong/kong.conf
        sudo kong migrations up -c /etc/kong/kong.conf
        sudo kong start -c /etc/kong/kong.conf
        curl -i http://localhost:8001/

        sudo kong restart
~~~

For install and configure Redis use this link: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-redis-on-ubuntu-16-04
