local responses = require "kong.tools.responses"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")
local utils = require "kong.tools.utils"
local cjson = require "cjson"
local users = require ("kong.plugins.keystone.views.users").User
local create_user = users.create_nonlocal
local get_user = users.get

local state = '106b6801-5e29-4059-b4e6-8c38ee3ee4d8' -- admin domain id
local function list_consumers(self, dao_factory)
    local consumers, err = dao_factory.consumer:find_all()
    kutils.assert_dao_error(err, "consumer find all")
    for i, v in pairs(consumers) do
        consumers[i].secret = nil
        consumers[i].links = {
            self = self:build_url(self.req.parsed_url.path..'/'..v.id)
        }
        if pcall(cjson.decode, v.description) then
            consumers[i].description = cjson.decode(v.description)
        end
    end

    return 200, {
        consumers = consumers,
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
        }
    }
end

local function create_consumer(self, dao_factory)
    if not self.params.consumer then
        responses.send_HTTP_BAD_REQUEST()
    end
    local consumer = {
        secret = self.params.consumer.secret or utils.uuid(),
        description = type(self.params.consumer.description) == 'string' and self.params.consumer.description or cjson.encode(self.params.consumer.description),
        id = self.params.consumer.id,
        auth_url = self.params.consumer.auth_url,
        token_url = self.params.consumer.token_url,
        userinfo_url = self.params.consumer.userinfo_url,
    }
    if not consumer.auth_url then
        responses.send_HTTP_BAD_REQUEST("Specify authentocation url for consumer")
    elseif not consumer.token_url then
        responses.send_HTTP_BAD_REQUEST("Specify token url for consumer")
    elseif not consumer.userinfo_url then
        responses.send_HTTP_BAD_REQUEST("Specify userinfo url for consumer")
    end

    if consumer.id then
        local temp, err = dao_factory.consumer:find({id = consumer.id})
        kutils.assert_dao_error(err, "consumer find")
        if temp then
            responses.send_HTTP_CONFLICT("Consumer already exists")
        end
    else
        consumer.id = utils.uuid()
    end
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
    local temp = cjson.decode(consumer.description)
    consumer.description = temp or consumer.description

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
    local cons_desc = type(self.params.consumer.description) == 'string' and self.params.consumer.description or cjson.encode(self.params.consumer.description)
    local consumer, err = dao_factory.consumer:update({description = cons_desc}, {id = consumer.id})
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

local function request_unscoped_token(self, dao_factory)
--    local consumer_id = self.req.headers['oauth_consumer_key']
--    local consumer_id = '649174633040-h5urg19giljnv4262ihsbh75a4hjtfrj.apps.googleusercontent.com' --google
    local consumer_id = '212814432631056' --facebook
    if not consumer_id then
        responses.send_HTTP_BAD_REQUEST()
    end
    local consumer, err = dao_factory.consumer:find({id = consumer_id})
    kutils.assert_dao_error(err, "consumer find")
    if not consumer then
        responses.send_HTTP_BAD_REQUEST("Consumer is not found")
    end
    --TODO why do we need requested project
--    self.req.headers['Requested-Project-Id'] = '533e9371-5070-435b-9aa6-9715b1d6003c'
--    local project_id = self.req.headers['Requested-Project-Id']
--    if not project_id then
--        responses.send_HTTP_BAD_REQUEST()
--    end
    local query = {
        response_type = 'code',
        scope = "email",
        client_id = consumer.id,
        redirect_uri = self:build_url("/v3/OS-OAUTH2/auth/callback/"..consumer.id),
        state = state,
        include_granted_scopes = true,
    }
    local url = consumer.auth_url..(consumer.auth_url:match("?") and '&' or '?')..ngx.encode_args(query)
--    ngx.req.set_header('Requested-Project-Id', self.req.headers['Requested-Project-Id'])
    ngx.redirect(url)
    error("returned from redirect")
end

local function request_unscoped_token_callback(self, dao_factory)
    -- We got the code param from oauth2 authorization endpoint
    -- and try to get user information
    if self.params.error then
        responses.send_HTTP_FORBIDDEN(self.params.error)
    end
    if self.params.state ~= state then
        responses.send_HTTP_FORBIDDEN()
    end
    local consumer_id = self.params.consumer_id
    local consumer, err = dao_factory.consumer:find({id = consumer_id})
    kutils.assert_dao_error(err, "consumer find")
    if not consumer then
        responses.send_HTTP_BAD_REQUEST("Consumer is not found")
    end

    -- Get access token from oauth2 token endpoint
    local http = require "resty.http"
    local httpc = http.new()
    local headers = {
        ['Content-Type'] = 'application/x-www-form-urlencoded'
    }
    local body = {
        code = self.params.code,
        client_id = consumer.id,
        client_secret = consumer.secret,
        redirect_uri = self:build_url("/v3/OS-OAUTH2/auth/callback/"..consumer.id),
        grant_type = 'authorization_code'
    }
    local res, err = httpc:request_uri(consumer.token_url, {
        method = 'POST',
        body = ngx.encode_args(body),
        ssl_verify = false,
        headers = headers
    })
    err = err and (type(err) == 'table' and cjson.encode(err) or err) or nil
    if err then error(err) end
    local resp = cjson.decode(res.body)
    if not resp.access_token then
        responses.send_HTTP_CONFLICT(resp)
    end

    -- Use access token to get user information: { id, email }
    local url = consumer.userinfo_url..(consumer.userinfo_url:match('?') and '&' or '?')
    url = url..'access_token='..resp.access_token
    local res, err = httpc:request_uri(url, {method = "GET", ssl_verify = false})
    if err then error(err) end
    local user_info = cjson.decode(res.body)
--    responses.send_HTTP_BAD_REQUEST(user_info)

    -- Check if user name was authorized before
    local temp, err = dao_factory.nonlocal_user:find_all({name = user_info.email})
    kutils.assert_dao_error(err, "nonlocal user find all by name")
    if not temp[1] then
        temp, err = dao_factory.local_user:find_all({name = user_info.email})
        kutils.assert_dao_error(err, "local user find all")
    end

    if temp[1] then
        -- If user found then check id and consumer for match
        local user_id = temp[1].user_id
        if user_id ~= user_info.id then
            responses.send_HTTP_CONFLICT()
        end
        local temp, err = dao_factory.access_token:find_all({authorizing_user_id = user_id})
        kutils.assert_dao_error(err, "access token find all")
        local access_token_info = temp[1]
        if access_token_info then
            if access_token_info.consumer_id ~= consumer.id then
                responses.send_HTTP_CONFLICT()
            end
            if access_token_info.expires_at and access_token_info.expires_at < os.time() then
                local _, err = dao_factory.access_token:delete({id = temp[1].id})
                kutils.assert_dao_error(err, 'access token')
            end
        end
    end

    -- Creating access token in base
    local access_token = {
        id = resp.access_token,
        access_secret = nil,
        authorizing_user_id = user_info.id,
        project_id = nil, --TODO Default?
        role_ids = nil,
        consumer_id = consumer.id,
        expires_at = resp.expires_in + os.time()
    }
    local _, err = dao_factory.access_token:insert(access_token)
    kutils.assert_dao_error(err, "access token insert")

    local user, err = dao_factory.user:find({id = user_info.id})
    kutils.assert_dao_error(err, "user find")
    if not user then
        -- Creating nonlocal user using email as name
        local s = self
        s.params = {
            user = {
                id = user_info.id,
                name = user_info.email
            }
        }
        local code, temp = create_user(s, dao_factory)
        if code ~= 201 then
            return code, temp
        end
        user = temp.user
    else
        -- Get user local or nonlocal
        local s = self
        s.params = {
            user_id = user_info.id
        }
        local code, temp = get_user(s, dao_factory)
        user = temp.user
    end

    local Tokens = kutils.provider()
    local token = Tokens.generate(dao_factory, user)
    local resp = {
        token = {
            methods = {"oauth2"},
            expires_at = kutils.time_to_string(token.expires),
            extras = token.extra,
            user = user,
            audit_ids = {utils.uuid()}, -- TODO
            issued_at = kutils.time_to_string(os.time())
        }
    }

    return 201, resp, {["X-Subject-Token"] = token.id}
end

local function list_access_tokens(self, dao_factory)
    local user_id = self.params.user_id
    local tokens, err = dao_factory.access_token:find_all ({authorizing_user_id = user_id})
    kutils.assert_dao_error(err, "access token find all")
    for i, v in pairs(tokens) do
        tokens[i].links = {
            self = self:build_url(self.req.parsed_url.path..'/'..v.id)
        }
    end
    local resp = {
        access_tokens = tokens,
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
        }
    }
    return 200, resp
end

local function get_access_token (self, dao_factory)
    local access_token, err = dao_factory.access_token:find({id = self.params.access_token_id})
    kutils.assert_dao_error(err, "access token find")
    if not access_token or access_token.authorizing_user_id ~= self.params.user_id then
        responses.send_HTTP_BAD_REQUEST()
    end
    access_token.links = {
        self = self:build_url(self.req.parsed_url.path)
    }
    return 200, {access_token = access_token}
end
local function revoke_access_token(self, dao_factory)
    local access_token, err = dao_factory.access_token:find({id = self.params.access_token_id})
    kutils.assert_dao_error(err, "access token find")
    if not access_token or access_token.authorizing_user_id ~= self.params.user_id then
        responses.send_HTTP_BAD_REQUEST()
    end
    local _, err = dao_factory.access_token:delete({id = self.params.access_token_id})
    kutils.assert_dao_error(err, "access token delete")

    return 204
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
    ['/v3/OS-OAUTH2/auth'] = {
        GET = function (self, dao_factory)
            responses.send(request_unscoped_token(self, dao_factory))
        end
    },
    ['/v3/OS-OAUTH2/auth/callback/:consumer_id'] = {
        GET = function (self, dao_factory)
            responses.send(request_unscoped_token_callback(self, dao_factory))
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
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_access_token", dao_factory, self.params)
            responses.send(revoke_access_token(self, dao_factory))
        end
    }
}

return {
    routes = routes,
    consumer = Consumer
}