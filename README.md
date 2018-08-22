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

Start cassandra:

~~~sh
$ sudo service cassandra start
~~~~

Now, if all goes well, you have Cassandra database.

## **Step 1: Kong**

[Kong](https://getkong.org/) is an open-source API proxy based on [NGINX](http://nginx.org/), which aims to «secure, manage and extend APIs and Microservices» thanks to a plugins oriented architecture.
 
Now you can install [Kong](https://konghq.com/install/) for [ubuntu](https://getkong.org/install/ubuntu/). Choose your version and download package.

~~~sh
$ sudo apt-get install openssl libpcre3 procps perl
$ sudo dpkg -i kong-community-edition-0.13.1.*.deb
~~~

## **Step 2: Keystone plugin**

The **keystone-plugin** executes some functions, which exist in [Keystone](https://docs.openstack.org/keystone/latest/), the [OpenStack](https://docs.openstack.org/) Identity Service. Keystone is an OpenStack service that provides API client authentication, service discovery, and distributed multi-tenant authorization by implementing [OpenStack’s Identity API](https://developer.openstack.org/api-ref/identity/v3/).

Code of the project can be found [here](https://github.com/ispras/keystone_plugin).

So, let's clone this project:

~~~sh
$ git clone https://github.com/ispras/keystone_plugin.git
~~~

Install openssl libraries

~~~sh
$ sudo apt-get install libssl1.0.0
$ sudo apt-get install libssl-dev
~~~

Now we will [integrate](https://getkong.org/docs/0.11.x/plugin-development/distribution/) this plugin in the local kong project. You need root rights.

<name>, <password> need for admin credentials and would be stored in **/etc/kong/admin_creds** file

~~~sh
$ cd keystone_plugin
$ sudo su
$ . install.sh <name> <password>
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

For stopping the Kong instance use following command:

~~~sh
$ sudo kong stop
~~~

If you have some problems and the code status of the response isn't 200 look at logs, you can find them in VM directory **/usr/local/kong/logs **and errors are described in file **error.log**:

Pay attention to the presence of the following lines:

* **"custom_plugins":["keystone"]**
* **"plugins":{"enabled_in_cluster":["keystone"] ...}**
* **"available_on_server":{..., "keystone":true, ...}**

If you have found those lines, keystone-plugin is running and is enabled. So you can try to check some functions provided by this plugin. First let's call the simplest GET-method, that shows us information about keystone version:

~~~sh
$ curl -i http://localhost:8000/v3/
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

{"version":{"links":[{"rel":"self","href":"http:\/\/localhost:8001\/v3\/"},{"rel":"describedby","href":"http:\/\/docs.openstack.org\/","type":"text\/html"}],"id":"v3.4","updated":"2018-01-01T00:00:00Z","status":"stable","media-types":[{"type":"application\/vnd.openstack.identity-v3+json","base":"application\/json"}]}}
~~~

To init keystone with necessary information run the script **init.sh**:

~~~sh
$ . init.sh <name> <password>
~~~

## **Step 3: Testing**

For manual testing of other methods you can use python tests.
