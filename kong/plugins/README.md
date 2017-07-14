# Development of Kong plugin on keystone-plugin example

The **keystone-plugin** executes some functions, which exist in [Keystone](https://docs.openstack.org/keystone/latest/), the [OpenStack](https://docs.openstack.org/) Identity Service. Keystone is an OpenStack service that provides API client authentication, service discovery, and distributed multi-tenant authorization by implementing [OpenStack’s Identity API](https://developer.openstack.org/api-ref/identity/v3/).

Code of the project can be found [here](https://github.com/lenaaxenova/keystone_plugin). 

The structure of this plugin looks like this:

~~~
keystone-plugin
├── kong/
|         ├── plugins/
│               ├── keystone/
│                    ├── migrations/
│                        └── cassandra.lua
│                    ├── api.lua
│                    ├── daos.lua
│                    ├── handler.lua
│                    ├── schema.lua
│                    ├── sha512.lua
│                    └── uuid4.lua
~~~

Let's review each file of this project. All of them are writed on Lua and in some files [lua-nginx-module API](https://github.com/openresty/lua-nginx-module) is used, which enables Lua scripting capabilities in [Nginx](http://nginx.org/). Instead of compiling Nginx with this module, Kong is distributed along with [OpenResty](https://openresty.org/en/), which already includes lua-nginx-module. OpenResty is not a fork of Nginx, but a bundle of modules extending its capabilities.

The structure of complete plugin looks like this:

~~~
complete-plugin
├── api.lua
├── daos.lua
├── handler.lua
├── hooks.lua
├── migrations
│   ├── cassandra.lua
│   └── postgres.lua
└── schema.lua
~~~

The file** hooks.lua**, that is not used in keystone-plugin, implements the invalidation event handlers for the datastore entities defined in **daos.lua** and is required if you are storing entities in the in-memory cache, in order to invalidate them when they are being updated/deleted in the datastore.

Two mandatory files that should be present in every plugin are: **handler.lua** and **schema.lua**. 

The **schema.lua** contains the configuration schema of the plugin. The only defined parametr in **keystone-plugin** is **token_expiration**, which is 7200 by default and it's required.

Here is the code of this module:

~~~lua
return {
  no_consumer = true,
  fields = {
    token_expiration = { required = true, type = "number", default = 7200 }
  }
}
~~~

The **handler.lua** module is an interface to implement, in which each function will be run at the desired moment in the lifecycle of a request. In this file we just declare the **keystone-plugin** which inherits from the BasePlugin which is the basic «class» of a Kong plugin and whose name / id is “**keystone**”. The code of **handler.lua** is below:

~~~lua
local BasePlugin = require "kong.plugins.base_plugin"

local KeystoneHandler = BasePlugin:extend()

function KeystoneHandler:new()
  KeystoneHandler.super.new(self, "keystone")
end

return KeystoneHandler
~~~

This plugin has to store custom entities in the database and interact with them, so we need modules, that will be responsible for interaction with datastore. This modules are **migrations/cassandra.lua** and **daos.lua**.

The **migrations/cassandra.lua** returns a table consisting of three fields:

* **name** - the name of migration. Note, that it must be unique.
* **up** - this field will be executed when Kong migrates forward. It must bring your database's schema to the latest state required by your plugin. This plugin interacts with Cassandra DB, so in this field we create tables and indices in datastore using [CQL notation](https://cassandra.apache.org/doc/old/CQL-2.2.html). If you want to use [PostgreSQL](https://www.postgresql.org/) it must be strings of SQL.
* **down** - this field must execute the necessary actions to revert your schema to its previous state, before **up** was ran. So we drop the objects, that whore created in **up** section.

Here is the code of **migrations/cassandra.lua**: 

~~~lua
return {
  {
    name = "keystone",
    up = [[
      CREATE TABLE IF NOT EXISTS keystone_user_info(
        user_id uuid,
	    tenant_id uuid,
        user_name text,
        password text,
	    email text,
        enabled boolean,
        PRIMARY KEY (user_id)
      );
      
      CREATE INDEX IF NOT EXISTS ON keystone_user_info(user_name);

      CREATE TABLE IF NOT EXISTS keystone_tenant_info(
        tenant_id uuid,
        tenant_name text,
        description text,
        enabled boolean,
        PRIMARY KEY (tenant_id)
      );
   
      CREATE INDEX IF NOT EXISTS ON keystone_tenant_info(tenant_name);

      CREATE TABLE IF NOT EXISTS keystone_token_info(
	    token_id uuid,
        user_id uuid,
        tenant_id uuid,
        issued_at timestamp,
	    expires timestamp,
        PRIMARY KEY (token_id)
      );
      
      CREATE TABLE IF NOT EXISTS keystone_uname_to_uid(
	    user_name text,
	    user_id uuid,
	    PRIMARY KEY (user_name)
      );

      CREATE INDEX IF NOT EXISTS ON keystone_uname_to_uid(user_id);
    
      CREATE TABLE IF NOT EXISTS keystone_tenname_to_tenid(
        tenant_name text, 
        tenant_id uuid,
        PRIMARY KEY (tenant_name)
      );

      CREATE INDEX IF NOT EXISTS ON keystone_tenname_to_tenid(tenant_id);

    ]],
    down = [[
      DROP TABLE keystone_user_info;
      DROP TABLE keystone_tenant_info;
      DROP TABLE keystone_token_info;
      DROP TABLE keystone_uname_to_uid;
      DROP TABLE keystone_tenname_to_tenid;
    ]]
  }
}
~~~

The structure of the data space is declared here. It will be used in the keystone plugin. 

The **daos.lua** defines a list of DAOs (Database Access Objects) that are abstractions of custom entities needed by your plugin and are stored in the datastore. For every stored entity we have to create a table, where will be declared the name of the stored table, its primary key, and information about all its fields. As a result we have to return a table with fields named as stored tables, that will refer on tables with description.

Here is the code of **daos.lua**:

~~~lua
local USER_SCHEMA = {
  primary_key = {"user_id"},
  table = "keystone_user_info",
  fields = {
    user_id = { type = "id" },
    tenant_id = { type = "id", required = true },
    user_name = { type = "string", required = true, unique = true },
    password = { type = "string", required = true },
    email = { type = "string", required = true },
    enabled = { type = "boolean", default = true }
  }
}

local UNAME_TO_UID_SCHEMA = {
  primary_key = {"user_name"},
  table = "keystone_uname_to_uid",
  fields = {
    user_name = { type = "string" },
    user_id = { type = "id", required = true, unique = true }
  }
}

local TENNAME_TO_TENID_SCHEMA = {
  primary_key = {"tenant_name"},
  table = "keystone_tenname_to_tenid",
  fields = {
    tenant_name = { type = "string" },
    tenant_id = { type = "id", required = true, unique = true }
  }
}

local TENANT_SCHEMA = {
  primary_key = {"tenant_id"},
  table = "keystone_tenant_info",
  fields = {
    tenant_id = { type = "id", required = true }, 
    tenant_name = { type = "string", required = true, unique = true },
    description = { type = "string" },
    enabled = { type = "boolean", default = true }
  }
}

local TOKEN_SCHEMA = {
  primary_key = {"token_id"},
  table = "keystone_token_info",
  fields = {
    token_id = { type = "id"},
    user_id = { type = "id", required = true },
    tenant_id = { type = "id", required = true },
    issued_at = { type = "timestamp", required = true },
    expires = { type = "timestamp", required = true }
  }
}


return {
  keystone_user_info = USER_SCHEMA,
  keystone_tenant_info = TENANT_SCHEMA,
  keystone_token_info = TOKEN_SCHEMA,
  keystone_uname_to_uid = UNAME_TO_UID_SCHEMA,
  keystone_tenname_to_tenid = TENNAME_TO_TENID_SCHEMA
}
~~~

The last module of this plugin is **api.lua**. It defines a list of endpoints to be available in the Admin API to interact with custom entities handled by your plugin. So all management logic is implemented in this module. As a result we return a table containing strings describing your routes and HTTP verbs they support. Routes are then assigned a simple handler function. Note, that [Lapis request object notation](http://leafo.net/lapis/reference/actions.html#request-object) is used here for interaction with request objects and  [Lapis routes & URL Patterns]( http://leafo.net/lapis/reference/actions.html#routes--url-patterns) for recording your routes. 

Let's look at some parts of the code of this module, which is quite cumbersome:

~~~lua
local responses = require "kong.tools.responses"
--local crud = require "kong.api.crud_helpers"
local uuid4 = require('uuid4')
local sha512 = require('sha512')
local cjson = require "cjson"

...

function get_headers()
...
end

function v20() 
    local body = {
            version = {
                status = 'stable',
                ...
                }
        }
    }

	return responses.send_HTTP_OK(body, get_headers())
end

function tenants(self, dao_factory)  
    ngx.req.read_body()
    local request = ngx.req.get_body_data()
    request = cjson.decode(request)
    
    local ten_name = request.tenant.name


     -- return with error if tenant exists 
    local res, err = dao_factory.keystone_tenname_to_tenid:find{tenant_name = ten_name} 
    
    if res then
        return responses.send(ERROR, "tenant with this name exists")
    end

    local ten_id = uuid4.getUUID() 
    
    res, err = dao_factory.keystone_tenant_info:insert({
        tenant_id = ten_id,
        tenant_name = ten_name,
        description = nil,
        enabled = true
    })
    
    if err then
        return responses.send_HTTP_OK(err, get_headers())
    end 
    
    res, err = dao_factory.keystone_tenname_to_tenid:insert({
        tenant_name = ten_name,
        tenant_id = ten_id
    }) 

    if err then
        return responses.send_HTTP_OK(err, get_headers())
    end 
    
	local body = {
					tenant = {
								description = nil,
								enabled = true,
								id = ten_id,
								name = ten_name
								--test_sha = test_sha_
							 }
				 }
	
    return responses.send_HTTP_OK(body, get_headers()) 
end

function delete_tenant(self, dao_factory)
    local ten_id = self.params.tenant_id
    local tenant_info, err = dao_factory.keystone_tenant_info:find{tenant_id = ten_id}
     
    if err then --tenant doesn't exist
        return responses.send(ERROR, err)
    end
    
    local ten_name = tenant_info.tenant_name
    
    dao_factory.keystone_tenant_info:delete{tenant_id = ten_id}
    dao_factory.keystone_tenname_to_tenid:delete{tenant_name = ten_name}
    
    return responses.send_HTTP_OK()
end

function get_user_info(self, dao_factory)
    ...
end

function delete_user(self, dao_factory)
	...
end

function users(request, dao_factory)
    	...
end

function tokens(request, dao_factory)
	...
end

return {
    ["/v2.0"] = {
        GET = function(self, dao_factory)
            v20()
        end
    },
    ["/v2.0/tenants/:tenant_id"] = {
        DELETE = function(self, dao_factory)
            delete_tenant(self, dao_factory)
        end
    },
  
    ["/v2.0/tenants"] = {
        POST = function(self, dao_factory)
            tenants(self, dao_factory)
        end
    },
    ["/v2.0/users"] = {
        POST = function(self, dao_factory)
            users(self, dao_factory)
        end
    },
    
    ["/v2.0/users/:user_id"] = {
        GET = function(self, dao_factory)
            get_user_info(self, dao_factory)
        end,
        
        DELETE = function(self, dao_factory)
            delete_user(self, dao_factory)
        end
    },
    ["/v2.0/tokens"] = {
        POST = function(self, dao_factory)
            tokens(self, dao_factory)
        end
    } 
}
~~~


Let's focus on some key moments. We import two kong libraries:

* [kong.tools.responses](https://github.com/Mashape/kong/blob/master/kong/tools/responses.lua) - in this library are kong helper methods to send HTTP responses to clients. In this code we can see two models of using it:

~~~lua
return responses.send(ERROR, "tenant with this name exists")
~~~

"**send**" method is used here, first argument is the code of the response, the type is number, second is the body of the response, that encodes in JSON format automatically, the type should be string or lua-table. Also it could receive the third argument with response headers, the type is lua-table. As a result it returns ngx.exit command from  [lua-nginx-module API](https://github.com/openresty/lua-nginx-module) with code, body and headers, that it had received.

The other way of using this module is:

~~~lua 
return responses.send_HTTP_OK(body, get_headers())
~~~ 

Here we use "send_HTTP_OK" method, that sends responses with 200 code status. It accepts the body of the response as first argument, the type is also string or lua-table, and the headers as second argument in lua-table type. 

In this library you can find the other functions that provides send responses with defined HTTP status code.

* [kong.api.crud_helpers](https://github.com/Mashape/kong/blob/master/kong/api/crud_helpers.lua) - this library is usefull for CRUD operations with datastore and helps making them more convenient for user. It isn't used in this module for the present. 

Now let's look at the simplest GET-method, that we call in */v2.0* location:

~~~lua
["/v2.0"] = {
        GET = function(self, dao_factory)
            v20()
        end
    }
~~~

It accepts two default arguments:

* **self** -  the Lapis request object;
* **dao_factory** - the DAO factory, that allow us to communicate with datastore;

Also it could receive the third argument, that is not used in this code:

* **helpers** - it is a lua-table with the following properties:
	*  *responses*: a module with helper functions to send HTTP responses.
	* *yield_error*: the [yield_error](http://leafo.net/lapis/reference/exception_handling.html#capturing-recoverable-errors) function from Lapis. To call when your handler encounters an error (from a DAO, for example). Since all Kong errors are tables with context, it can send the appropriate response code depending on the error (Internal Server Error, Bad Request, etc...).

In this GET-function we just return the default message, calling v20() function.

Then let's consider POST-method in */v2.0/tenants* location:

~~~lua
  ["/v2.0/tenants"] = {
        POST = function(self, dao_factory)
            tenants(self, dao_factory)
        end
    }
~~~

This part of code that describes this endpoint is almost the same as the previous method, but the calling function *tenants()* is more complicated:

~~~lua 
function tenants(self, dao_factory)  
    ngx.req.read_body()
    local request = ngx.req.get_body_data()
    request = cjson.decode(request)
    
    local ten_name = request.tenant.name

    local res, err = dao_factory.keystone_tenname_to_tenid:find{tenant_name = ten_name} 
    
    if res then
        return responses.send(ERROR, "tenant with this name exists")
    end

    local ten_id = uuid4.getUUID() 
    
    res, err = dao_factory.keystone_tenant_info:insert({
        tenant_id = ten_id,
        tenant_name = ten_name,
        description = nil,
        enabled = true
    })
    
    if err then
        return responses.send_HTTP_OK(err, get_headers())
    end 
    
    res, err = dao_factory.keystone_tenname_to_tenid:insert({
        tenant_name = ten_name,
        tenant_id = ten_id
    }) 

    if err then
        return responses.send_HTTP_OK(err, get_headers())
    end 
    
	local body = {
					tenant = {
								description = nil,
								enabled = true,
								id = ten_id,
								name = ten_name
							 }
				 }
	
    return responses.send_HTTP_OK(body, get_headers()) 
end
~~~

First we have to receive and read the body of the request, for this we use two functions from [lua-nginx-module API](https://github.com/openresty/lua-nginx-module):

~~~lua
ngx.req.read_body()
local request = ngx.req.get_body_data()
~~~

So now in variable *request* is the body of the request as a JSON string, that we have to parse, if we want to get the arguments.

Then let's look at strings, where we interact with the DAOs factory:

~~~lua
local res, err = dao_factory.keystone_tenname_to_tenid:find{tenant_name = ten_name} 
 ...
 
 res, err = dao_factory.keystone_tenant_info:insert({
        tenant_id = ten_id,
        tenant_name = ten_name,
        description = nil,
        enabled = true
    })
~~~
 
First, we try to find in *keystone_tenname_to_tenid* table the field by their primary key. We have to send this parameter as lua-table with fields coincided with the fields of requested stored table fields, that determine the primary key. If the field was found, it returns this entity in *res* variable as lua-table.

Then we try to insert in *keystone_tenant_info* table the new entity. It is given also as a lua-tables with fields coincided with all the fields of requested stored table. 

Finaly, let's look at the DELETE-method in */v2.0/tenants/:tenant_id* location, in which is used parameter *tenant_id* according to [Lapis routes & URL Patterns](http://leafo.net/lapis/reference/actions.html#routes--url-patterns):

~~~lua
 ["/v2.0/tenants/:tenant_id"] = {
        DELETE = function(self, dao_factory)
            delete_tenant(self, dao_factory)
        end
    }
~~~

There is nothing new here, so let's consider *delete_tenant() *function:

~~~lua
function delete_tenant(self, dao_factory)
    local ten_id = self.params.tenant_id
    local tenant_info, err = dao_factory.keystone_tenant_info:find{tenant_id = ten_id}
     
    if err then --tenant doesn't exist
        return responses.send(ERROR, err)
    end
    
    local ten_name = tenant_info.tenant_name
    
    dao_factory.keystone_tenant_info:delete{tenant_id = ten_id}
    dao_factory.keystone_tenname_to_tenid:delete{tenant_name = ten_name}
    
    return responses.send_HTTP_OK()
end
~~~

The *tenant_id* value is placed in *self.params.tenant_id*, so we can catch it and then delete the tenant entity with this id. For this we use *delete* method, which accepts the lua-table with primary keys of the requested stored table. 
