local responses = require "kong.tools.responses"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")
local utils = require "kong.tools.utils"
local cjson = require "cjson"
local oidc = require ("resty.openidc")

local function list_consumers(self, dao_factory)
    local consumers, err = dao_factory.consumer:find_all()
    kutils.assert_dao_error(err, "consumer find all")
    for i, v in pairs(consumers) do
        consumers.secret = nil
        consumers.links = {
            self = self:build_url(self.req.parsed_url.path)
        }
    end

    return 200, {
        consumers = consumers,
        links = {
            next = "null",
            previous = "null",
            self = self:build_url(self.req.parsed_url.path)
        }
    }
end

local function create_consumer(self, dao_factory)
    if not self.params.consumer then
        responses.send_HTTP_BAD_REQUEST()
    end
    local consumer = {
        secret = utils.uuid(),
        description = self.params.consumer.description,
        id = utils.uuid()
    }
    local _, err = dao_factory.consumer:insert(consumer)
    kutils.assert_dao_error(err, "consumer insert")
    consumer.links = {
        self = self:build_url(self.req.parsed_url.path..'/'..consumer.id)
    }

    return 201, {
        consumer = consumer
    }
end

local function get_consumer(self, dao_factory)
    local consumer, err = dao_factory.consumer:find({id = self.params.consumer_id})
    kutils.assert_dao_error(err, "consumer find")
    if not consumer then
        responses.send_HTTP_BAD_REQUEST("Consumer with requested id doesn't exist")
    end
    consumer.secret = nil
    consumer.links = {
        self = self:build_url(self.req.parsed_url.path)
    }

    return 200, {
        consumer = consumer
    }
end

local function update_consumer(self, dao_factory)
    local consumer, err = dao_factory.consumer:find({id = self.params.consumer_id})
    kutils.assert_dao_error(err, "consumer find")
    if not consumer then
        responses.send_HTTP_BAD_REQUEST("Consumer with requested id doesn't exist")
    end
    if not self.params.consumer or not self.params.consumer.description then
        responses.send_HTTP_BAD_REQUEST()
    end
    local consumer, err = dao_factory.consumer:update({description = self.params.consumer.description}, {id = consumer.id})
    kutils.assert_dao_error(err, "consumer update")
    consumer.secret = nil
    consumer.links = {
        self = self:build_url(self.req.parsed_url.path)
    }

    return 200, {
        consumer = consumer
    }
end
local function delete_consumer(self, dao_factory)
    local consumer, err = dao_factory.consumer:find({id = self.params.consumer_id})
    kutils.assert_dao_error(err, "consumer find")
    if not consumer then
        responses.send_HTTP_BAD_REQUEST("Consumer with requested id doesn't exist")
    end

    local tokens, err = dao_factory.access_token:find_all({consumer_id = consumer.id})
    kutils.assert_dao_error(err, "access token find all")
    for _, v in pairs(tokens) do
        local _, err = dao_factory.access_token:delete({id = v.id})
        kutils.assert_dao_error(err, "access token delete")
    end
    local tokens, err = dao_factory.request_token:find_all({consumer_id = consumer.id})
    kutils.assert_dao_error(err, "request token find all")
    for _, v in pairs(tokens) do
        local _, err = dao_factory.request_token:delete({id = v.id})
        kutils.assert_dao_error(err, "request token delete")
    end

    local _, err = dao_factory.consumer:delete({id = consumer.id})
    kutils.assert_dao_error(err, "consumer delete")

    return 204
end

local function parse_header(header)
    local _, num = header:gsub('\",', '')
    local format = '(.*)=\"(.*)\",%s*(.*)=\"(.*)\"'
    for i = 2, num do
        format = format..",%s*(.*)=\"(.*)\""
    end
    local a = {header:match(format) }
    local ret = {}
    for i = 1, #a, 2 do
        ret[a[i]] = a[i + 1]
    end
    return ret
end

local function parse_signature(auth)
    if not auth then
        responses.send_HTTP_UNAUTHORIZED()
    end
    if type(auth) ~= 'table' then
        responses.send_HTTP_BAD_REQUEST(parse_header(auth))
    end

    responses.send_HTTP_BAD_REQUEST(auth)
end

local function create_request_token(self, dao_factory)
    -- TODO The request MUST be signed and contains the following parameters:
    local opts = {
        discovery = 'https://accounts.google.com/.well-known/openid-configuration',
--        discovery = 'https://accounts.google.com/o/oauth2/v2/auth',
        ssl_verify = "no",
        timeout = 2000,
        redirect_uri_path = "/v3/OS-OAUTH2/callback",
        client_id = '649174633040-h5urg19giljnv4262ihsbh75a4hjtfrj.apps.googleusercontent.com',
        client_secret = 'LMUHFLQJSRF2YB4zU8cRJTdY',
        scope = "https://www.googleapis.com/auth/drive.metadata.readonly"
    }
    local res, err = oidc.authenticate(opts)
    responses.send_HTTP_BAD_REQUEST({res, err})

    local project_id = self.req.headers['Requested-Project-Id']
    if not project_id then
        responses.send_HTTP_BAD_REQUEST()
    end
--    responses.send_HTTP_BAD_REQUEST(ngx.req.get_headers())
    local auth = parse_signature(ngx.req.get_headers()['Authorization'])

end

local function check_response(self, dao_factory)
    ngx.req.read_body()
    local request = ngx.req.get_body_data()
    request = request and cjson.decode(request) or "NULL"
    responses.send_HTTP_OK({request = request, params = self.params})
end

local Consumer = {
    list = list_consumers,
    create = create_consumer,
    get = get_consumer,
    update = update_consumer,
    delete = delete_consumer
}


local routes = {
    ['/v3/OS-OAUTH2/consumers'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_consumers", dao_factory, self.params)
            responses.send(list_consumers(self, dao_factory))
        end,
        POST = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_consumer", dao_factory, self.params)
            responses.send(create_consumer(self, dao_factory))
        end
    },
    ['/v3/OS-OAUTH2/consumers/:consumer_id'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_consumer", dao_factory, self.params)
            responses.send(get_consumer(self, dao_factory))
        end,
        PATCH = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:update_consumer", dao_factory, self.params)
            responses.send(update_consumer(self, dao_factory))
        end,
        DELETE = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_consumer", dao_factory, self.params)
            responses.send(delete_consumer(self, dao_factory))
        end
    },
    ['/v3/OS-OAUTH2/request_token'] = {
        GET = function (self, dao_factory)
--            policies.check(self.req.headers['X-Auth-Token'], "identity:create_request_token", dao_factory, self.params)
            responses.send(create_request_token(self, dao_factory))
        end
    },
    ['/v3/OS-OAUTH2/callback'] = {
        GET = function (self, dao_factory)
            responses.send(check_response(self, dao_factory))
        end
    },
    ['/v3/OS-OAUTH2/authorize/:request_token_id'] = {
        PUT = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:authorize_request_token", dao_factory, self.params)
            responses.send(authorize_request_token(self, dao_factory))
        end
    },
    ['/v3/OS-OAUTH2/access_token'] = {
        POST = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_access_token", dao_factory, self.params)
            responses.send(create_access_token(self, dao_factory))
        end
    },
    ['/v3/users/:user_id/OS-OAUTH2/access_tokens'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_access_tokens", dao_factory, self.params)
            responses.send(list_access_tokens(self, dao_factory))
        end
    },
    ['/v3/users/:user_id/OS-OAUTH2/access_tokens/:access_token_id'] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_access_token", dao_factory, self.params)
            responses.send(get_access_token(self, dao_factory))
        end,
        DELETE = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:revoke_access_token", dao_factory, self.params)
            responses.send(revoke_access_token(self, dao_factory))
        end
    },
    ['/v3/users/:user_id/OS-OAUTH2/access_tokens/:access_token_id/roles'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_roles_for_access_token", dao_factory, self.params)
            responses.send(list_roles_for_access_token(self, dao_factory))
        end
    },
    ['/v3/users/:user_id/OS-OAUTH2/access_tokens/:access_token_id/roles'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_role_for_access_token", dao_factory, self.params)
            responses.send(get_role_for_access_token(self, dao_factory))
        end
    }
}

return {
    routes = routes,
    auth = authenticate_with_identity_api
}