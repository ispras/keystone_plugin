local responses = require "kong.tools.responses"
local policies = require ("kong.plugins.keystone.policies")
local kfernet = require ("kong.plugins.keystone.fernet")
local urandom = require 'randbytes'
local cjson = require "cjson"

-- NOTE: some modules are called inside functions
-- because of lapis error "attempt to index upvalue (a userdata value)
-- for more information https://github.com/Neopallium/lua-pb/issues/28

local function get_keys(config)
    local redis = require ("kong.plugins.keystone.redis")
    local red, err = redis.connect(config) -- TODO cache
    if err then error(err) end
    local temp, err = red:get("fernet_keys")
    if err then error(err) end
    if temp ~= ngx.null then
        local temp = cjson.decode(temp)
        local keys = {}
        for k, v in pairs(temp) do
            keys[tonumber(k)] = v
        end
        return keys
    end
    responses.send_HTTP_CONFLICT("No generated keys found. Call key rotation")
end

local function get_primary(config)
    local keys = get_keys(config)
    return keys[#keys]
end

local function generate_key()
    local secret = urandom(32)
    secret = kfernet.base64_encode(secret)
    return secret
end

local function rotate_keys(config)
    local kutils = require ("kong.plugins.keystone.utils")
    local redis = require ("kong.plugins.keystone.redis")
    local config = kutils.config_from_dao(config)
    local max_active_keys = config['fernet_tokens_max_active_keys']
    local red, err = redis.connect(config)
    kutils.assert_dao_error(err, "redis connect")
    local temp, err = red:get("fernet_keys")
    kutils.assert_dao_error(err, "redis get")
    local keys = {}
    if temp ~= ngx.null then
        temp = cjson.decode(temp)
        for k, v in pairs(temp) do
            keys[tonumber(k)] = v
        end
        if #keys+1 < max_active_keys then
            keys[#keys+1] = keys[0]
            keys[0] = generate_key()
        else
            for i = 1, max_active_keys - 2 do
                keys[i] = keys[i+1]
            end
            keys[max_active_keys-1] = keys[0]
            keys[0] = generate_key()
        end
    else
        keys = {[0] = generate_key(), [1] = generate_key() }
    end
    temp = cjson.encode(keys)
    local _, err = red:set("fernet_keys", temp)
    kutils.assert_dao_error(err, "redis set")
    return keys
end
local function revoke_keys(config)
    local redis = require ("kong.plugins.keystone.redis")
    local red, err = redis.connect(config)
    if err then error(err) end
    local temp, err = red:del("fernet_keys")
    if err then error(err) end
end

local routes = {
    ["/v3/fernet_keys"] = {
        POST = function(self, dao_factory)
            policies.check(self, dao_factory, "admin_required")
            responses.send_HTTP_CREATED(rotate_keys())
        end,
        DELETE = function(self, dao_factory)
            policies.check(self, dao_factory, "admin_required")
            responses.send_HTTP_NO_CONTENT(revoke_keys())
        end
    }
}
return {
    get= get_keys,
    get_primary = get_primary,
    rotate_keys = rotate_keys,
    routes = routes
}