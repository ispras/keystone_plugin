local responses = require "kong.tools.responses"
local crud = require "kong.api.crud_helpers"
local uuid4 = require('uuid4')
local sha512 = require('sha512')
local cjson = require "cjson"

local SERVER_IP = '127.0.0.1'
local HOST = '0.0.0.0'
local PORT = 35357

local ERROR = 413

function get_headers()
	--local req_id = PREFIX .. COUNTER
    local headers = {}
    headers["x-openstack-request-id"] = uuid4.getUUID() -- uuid (uuid4)
    headers.Vary = "X-Auth-Token"
    return headers
end

function v20() 
    local body = {
            version = {
                status = 'stable',
                updated = '2014-04-17T00:00:00Z',
                id = 'v2.0',
                ['media-types'] = {{
                    base = 'application/json',
                    type = 'application/vnd.openstack.identity-v2.0+json'
                }},
                links = {
                    {href = "http://" .. SERVER_IP .. ':35357/v2.0/', rel = 'self'},
                    {href = 'http://docs.openstack.org/', type = 'text/html', rel = 'describedby'}
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
    local uid = self.params.user_id
    local user_info, err = dao_factory.keystone_user_info:find{user_id = uid}
    
    if err then --user doesn't exist
        return responses.send(ERROR, err)
    end
    
    local user_name = user_info.user_name
    local body = {
					user = {
					        domain_id = "default",							
							enabled = true,
							id = uid,
							links = {
							    self = "http://localhost:5000/v3/users/ec8fc20605354edd91873f2d66bf4fc4"
                            },
							name = user_name
						   }
				}
	
    return responses.send_HTTP_OK(body, get_headers())
end

function delete_user(self, dao_factory)
    local uid = self.params.user_id
    local user_info, err = dao_factory.keystone_user_info:find{user_id = uid}
    
    if err then --user doesn't exist
        return responses.send(ERROR, err)
    end
    
    local uname = user_info.user_name
    
    dao_factory.keystone_user_info:delete{user_id = uid}
    dao_factory.keystone_uname_to_uid:delete{user_name = uname}
    
    return responses.send_HTTP_OK()
end

function users(request, dao_factory)
    ngx.req.read_body()
    local request = ngx.req.get_body_data()
    request = cjson.decode(request)

	local uname = request.user.name
	local ten_id = request.user.tenantId

	local passwd = sha512.crypt(request.user.password)
	local email_ = request.user.email
	
	if not ten_id then
	    return responses.send(ERROR, "bad tenant")
	end
	
	local res, err = dao_factory.keystone_uname_to_uid:find{user_name = uname} 
    
    if res then
        return responses.send(ERROR, "user with this name exists")
    end
    
    local uid = uuid4.getUUID()
    
    res, err = dao_factory.keystone_user_info:insert({
        user_id = uid,
        tenant_id = ten_id,
        user_name = uname,
        password = passwd,
        email = email_,
        enabled = true,
        created_at = nil
    })
    
    if err then
        return responses.send_HTTP_OK(err, get_headers())
    end 
    
    res, err = dao_factory.keystone_uname_to_uid:insert({
        user_name = uname,
        user_id = uid
    }) 

    if err then
        return responses.send_HTTP_OK(err, get_headers())
    end 
  
	local body = {
					user = {
					        username = uname,
							name = uname,
							id = uid,
							enabled = true,
							email = email_, --'c_rally_9aa720c3_lk5OUaDz@email.me',
							tenantID = ten_id
						   }
				}
	
    return responses.send_HTTP_OK(body, get_headers())
end

function tokens(request, dao_factory)
    ngx.req.read_body()
    local request = ngx.req.get_body_data()
    request = cjson.decode(request)

    local uname = request.auth.passwordCredentials.username
    local password = sha512.crypt(request.auth.passwordCredentials.password)
    local ten_name = request.auth.tenantName
    
    local uname_to_uid, err = dao_factory.keystone_uname_to_uid:find{user_name = uname} 
    
    if err then
        return responses.send(ERROR, "user with this name doesn't exist")
    end
    
    local uid = uname_to_uid.user_id
    
    local user_info, err = dao_factory.keystone_user_info:find{user_id = uid}
    
    if err then
        return responses.send(ERROR, err)
    end
    
    local upass = user_info.password

    if not sha512.verify(request.auth.passwordCredentials.password, upass) then
	    return responses.send(ERROR, "incorrect password") --incorrect password
    end
    
    local tenname_to_tenid, err = dao_factory.keystone_tenname_to_tenid:find{tenant_name = ten_name} 
    
     if err then --tenant doesn't exist
        return responses.send(ERROR, err)
    end
    
    if user_info.tenant_id ~= tenname_to_tenid.tenant_id then --user doesn't belong to this tenant
	    return responses.send(ERROR, "user doesn't belong to this tenant")
    end
    
    --sha512.crypt(os.clock())          
    local token_id_ = uuid4.getUUID()--sha512.crypt(os.clock())
	local issued_at_u = os.time()
	local expires_u = issued_at_u + 60 * 60;
	local issued_at_ = os.date("%Y-%m-%dT%H:%M:%S", issued_at_u)
	local expires_ = os.date("%Y-%m-%dT%H:%M:%S", expires_u)
    
    local ten_id = user_info.tenant_id
    
    --return responses.send_HTTP_OK(sha512.crypt(os.clock()), get_headers())

    local res, err = dao_factory.keystone_token_info:insert({
        token_id = token_id_,
        user_id = uid,
        tenant_id = ten_id,
        issued_at = issued_at_u,
        expires = expires_u
    })
    
    if err then
        return responses.send_HTTP_OK(err, get_headers())
    end 
    
    local tenant_info, err = dao_factory.keystone_tenant_info:find{tenant_id = ten_id} 
    
    if err then
        return responses.send(ERROR, err)
    end
    
    local ten_description = tenant_info.description
    local ten_enabled = tenant_info.enabled
    
	local body = {
					access = {
							token = {
								issued_at = issued_at_,
								expires = expires_,
								id = token_id_,
								tenant = {
										description = ten_description, --"Admin tenant",
										enabled = ten_enabled, --true,
                                        id = ten_id, --"6dcbaf4b07d64f91b87c4bc2ee8a0929",
                                        name = ten_name --"admin"
                                },
                                audit_ids = {"A8a7LO3oShC9PuaHS9mfHQ"}
                            },
                            serviceCatalog = {{
                                endpoints = {{
                                    adminURL = "http://" .. SERVER_IP .. ":35357/v2.0",
                                    region = "RegionOne",
                                    internalURL = "http://" .. SERVER_IP .. ":5000/v2.0",
                                    id = "3e8987c7202d475a976d5b3c5d4d336e",
                                    publicURL = "http://" .. SERVER_IP .. ":5000/v2.0"
                                }},
                                type = "identity",
                                name = "keystone"
                            }},
                            user = {
                                username = uname, --"admin",
                                id = uid, --"90407f560e344ad39c6727a358278c35",
                                roles = {
                                    {name = "_member_"},
                                    {name = "admin"}
                                },
                                name = "admin"
                            },
                            metadata = {
                                is_admin = 0,
                                roles = {
                                    "9fe2ff9ee4384b1894a90878d3e92bab",
                                    "be2b06f63ff84be595a18b1a1e2bb83d"
                                    }
                            }
                        }
                    }

    return responses.send_HTTP_OK(body, get_headers())
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
