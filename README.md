#Keystone plugin for Kong

This instruction will relate you how to prepare the environment for developing Kong plugins and will describe how to install, run and test the Keystone plugin. 

###**Step 0: Vagrant+Virtualbox**
 
First, you need to install [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/). So, you can find links for downloading it on their websites.
 
For Vagrant:

![](https://vfc.cc/a94b8e6a5128d549352051a366ad3144) 

For VirtualBox: 
 
 ![](https://vfc.cc/7a7c2c2cd3bb3efaec7bbc7c4492933d) 
 
You should choose **AMD64** for your Ubuntu version!  

 
Create new directory, for example, named as vagrant:

~~~sh
$ mkdir ~/vagrant
$ cd ~/vagrant
~~~

Save that packages in this directory and then unzip them:

~~~sh
 $ sudo dpkg -i vagrant_*.deb
 $ sudo dpkg -i virtualbox-*.deb
~~~
 
Also you have to install **linux-headers**:

~~~sh
$ sudo apt-get install linux-headers-$(uname -r)
~~~
  
Now, if all goes well, you have Vagrant, VirtualBox and linux-headers installed in your system.
 
Also make sure, that visualization is allowed in your system and you have capabilities for creating virtual machines. This settings you can find in **BIOS**.
 
###**Step 1: Kong+Vagrant**

[Kong](https://getkong.org/) is an open-source API proxy based on [NGINX](http://nginx.org/), which aims to «secure, manage and extend APIs and Microservices» thanks to a plugins oriented architecture.
 
Now you can install a [Vagrant image of Kong](https://github.com/Mashape/kong-vagrant). In this image is already installed and pre-configured environment for the Kong development: **Lua**, **luarocks**, **Cassandra** and etc. 
 
Clone this vagrant repository:

~~~sh
$ git clone https://github.com/Mashape/kong-vagrant
$ cd kong-vagrant
~~~
   
Build the machine:

~~~sh
$ sudo vagrant up
~~~
   
SSH into the VM:

~~~sh
$ sudo vagrant ssh
~~~
   
If you don’t have any problems with starting the VM, you can start Kong into the VM with this command:

~~~sh
$ kong start
~~~
 
Kong is now started and is available on the default ports:

* 8000 Proxy port
* 8443 SSL Proxy port
* 8001 Admin API
* 8444 SSL Admin API
 
To verify Kong is running successfully, execute the following command from the host machine:

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

For stoping the Kong instance use following command:

~~~sh
$ kong stop
~~~ 
    
After this destroy the VM, you can do this executing from the host machine following commands:

~~~sh
$ vagrant global-status
~~~

You should receive response like this:

~~~sh
id       name    provider   state   directory 
------------------------------------------------------------------------------
7c52087  default virtualbox running /home/lenaaxenova/virtualbox/kong-vagrant 
 
The above shows information about all known Vagrant environments
on this machine. This data is cached and may not be completely
up-to-date. To interact with any of the machines, you can go to
that directory and run Vagrant, or you can use the ID directly
with Vagrant commands from any directory. For example:
"vagrant destroy 1a2b3c4d"
~~~
 
Now execute destroy command with id of your VM:
    
~~~sh
$ sudo vagrant destroy 7c52087
~~~
   
Make sure that you are inside kong-vagrant directory and clone the Kong repository and repository with kong-plugin template:
 
~~~sh
$ git clone https://github.com/Mashape/kong
$ git clone https://github.com/Mashape/kong-plugin
~~~
    
Build a box with a folder synced to your local Kong and plugin source:
 
~~~sh
$ sudo vagrant up
~~~
     
SSH into the Vagrant machine, and setup the development environment:
~~~sh
$ sudo vagrant ssh 
$ cd /kong
$ sudo make dev
~~~

Let’s run kong with loaded custom test plugin:
 
~~~sh
$ export KONG_CUSTOM_PLUGINS=myPlugin
$ cd /kong
$ bin/kong start
~~~
 
Verify that Kong has loaded the plugin successfully, execute the following command from the host machine:
 
~~~sh
$ curl http://localhost:8001
~~~
 
Add API and custom plugin from the host machine:
 
~~~sh 
$ curl -i -X POST \
     --url http://localhost:8001/apis/ \
    --data 'name=mockbin' \
      --data 'upstream_url=http://mockbin.org/request' \
      --data 'uris=/'
 
$ curl -i -X POST \
      --url http://localhost:8001/apis/mockbin/plugins/ \
      --data 'name=myPlugin'
~~~ 
 
Check whether it is working by making a request from the host:

~~~sh 
$ curl -i http://localhost:8000
~~~
 
The response you get should be an echo (by Mockbin) of the request. But in the response headers the plugin has now inserted a header Bye-World.
If you have some problems look at logs, you can find them into the VM in this directory:
 
~~~sh
 $ cd /usr/local/kong/logs
~~~
 
 Don't forget to destroy this VM before perfoming the next step!
 
###**Step 2: Keystone plugin**

The **keystone-plugin** executes some functions, which exist in [Keystone](https://docs.openstack.org/keystone/latest/), the [OpenStack](https://docs.openstack.org/) Identity Service. Keystone is an OpenStack service that provides API client authentication, service discovery, and distributed multi-tenant authorization by implementing [OpenStack’s Identity API](https://developer.openstack.org/api-ref/identity/v3/).

Code of the project you can find [here](https://github.com/lenaaxenova/keystone_plugin). 

So, let's clone this project:

~~~sh
$ cd ~ 
$ git clone https://github.com/lenaaxenova/keystone_plugin
~~~

Now we will integrate this plugin in the local kong project and run it on Vagrant VM. Copy directory with keystone plugin to this directories:

~~~sh
~/kong-vagrant/kong/kong/plugins
~/kong-vagrant/kong-plugin/kong/plugins
~~~

You can execute following commands:

~~~sh
$ cp -a ~/keystone_plugin/kong/plugins/keystone . ~/kong-vagrant/kong/kong/plugins
$ cp -a ~/keystone_plugin/kong/plugins/keystone . ~/kong-vagrant/kong-plugin/kong/plugins
~~~

Copy *sha512* and *uuid4* libraries to **~/kong-vagrant/kong-plugin** directory:

~~~sh
$ cp ~/keystone_plugin/sha512.lua ~/kong-vagrant/kong-plugin/sha512.lua
$ cp ~/keystone_plugin/uuid4.lua ~/kong-vagrant/kong-plugin/uuid4.lua
~~~

Make sure that at this moment the structure of your files looks like this:

~~~
|kong-vagrant/
|	├── kong/
|	|    ├── kong/
|	|         ├── plugins/
|	│               ├── keystone/
|	│                    ├── migrations/
|	│                        └── cassandra.lua
|	│                    ├── api.lua
|	│                    ├── daos.lua
|	│                    ├── handler.lua
|	│                    ├── schema.lua
|	│                    ├── sha512.lua
|	│                    └── uuid4.lua
|	└── ...
|	├── kong-plugin/
|	|    ├── kong/
|	|         ├── plugins/
|	│               ├── keystone/
|	│                    ├── migrations/
|	│                        └── cassandra.lua
|	│                    ├── api.lua
|	│                    ├── daos.lua
|	│                    ├── handler.lua
|	│                    ├── schema.lua
|	│                    ├── sha512.lua
|	│                    └── uuid4.lua
|	└── ...
└── ...
~~~

Also you should modify rockspecs files adding information about keystone-plugin and required lua-modules. You can do it copying rockspecs files from keystone-plugin project to it:

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

Let's start kong selecting our configuration file:

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

 If you have some problems and the code status of the response isn't 200 look at logs, you can find them into the VM in this directory **/usr/local/kong/logs **and errors are described in file **error.log**:

 In case you don't have any problems let's add API and keystone as custom plugin from the host machine:
 
~~~sh
$  curl -i -X POST   --url http://localhost:8001/apis/   --data 'name=mockbin'   --data 'upstream_url=http://mockbin.org/request'   --data 'uris=/'
$  curl -i -X POST   --url http://localhost:8001/apis/mockbin/plugins/   --data 'name=keystone'
~~~

Then try to check the Admin host 8001 again:

~~~sh
$ curl http://localhost:8001
~~~

You should recive response like this:

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

If you have found that lines, keystone-plugin is running and is enabled. So you can try to check some functions provided by this plugin. First let's call the simplest GET-method, that shows us information about keystone version:

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
             "password": "password",
             "email": "some@email.com"
        }
    }
}
~~~

In field "tenantId" should be ID of the admin-tenant that we have created yet. This ID you have received in the response on that query. 

In Mozila REST-extension it will look like this:

![](https://vfc.cc/29c9b77c2f108e1832baa910f9942b36)

You can test the other GET-method that shows information of a user by his ID via link http://localhost:8001/v2.0/users/:user_id. Instead "user_id" you should write ID of the admin-user that we have created yet. This ID you have received in the response on that query. 

Now you can receive a token for this user. It will be POST-method via link http://localhost:8001/v2.0/tokens with following message in JSON format:

~~~javascript
{
    "auth": {
        "passwordCredentials": {
            "username": "admin", 
            "password": "password"
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

This queries will delete entities by their ID.


###**Step 3: Testing**
