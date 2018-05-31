local errors = require "kong.dao.errors"
local redis = require "kong.plugins.keystone.redis"

local function check_default_crypt_strenght(default_crypt_strength)
    if default_crypt_strength > 10000 or default_crypt_strength < 1000 then
        return false, "Minimum value for crypt_strength is 1000, maximum value is 10000"
    end

    return true
end

return {
    no_consumer = true,
    fields = {
        --default block
        default_crypt_strength = { type = "number", func = check_default_crypt_strenght, default = 10000 },
        default_public_endpoint = { type = "string", default = 'None' }, --not implemented
        default_admin_endpoint = { type = "string", default = 'None' }, --not implemented
        default_max_project_tree_depth = { type = "number", default = 5 }, --not implemented
        default_max_param_size = { type = "number", default = 64 }, --not implemented
        default_max_token_size = { type = "number", default = 255 }, --not implemented
        default_member_role_id = { type = "string", default = '9fe2ff9ee4384b1894a90878d3e92bab' }, --not implemented
        default_member_role_name = { type = "string", default = '_member_' }, --not implemented
        default_list_limit = { type = "number", default = -1 }, --not implemented

        --auth block
        auth_methods = { type = "array", default = {"external", "password", "token", "oauth2", "mapped"}}, --not implemented
        auth_password = { type = "string", default = '' }, --not implemented

        --cors block
        cors_allowed_origin = { type = "array", default = {}}, --not implemented
        cors_allow_credentials = {type = "boolean", default = true}, --not implemented
        cors_expose_headers = { type = "array", default = {"X-Auth-Token", "X-Openstack-Request-Id", "X-Subject-Token"}}, --not implemented
        cors_allow_methods = { type = "array", default = {"GET", "PUT", "POST", "DELETE", "PATCH"}}, --not implemented
        cors_allow_headers = { type = "array", default = {"X-Auth-Token", "X-Openstack-Request-Id", "X-Subject-Token", "X-Project-Id,X-Project-Name",
                            "X-Project-Domain-Id", "X-Project-Domain-Name,X-Domain-Id", "X-Domain-Name"}}, --not implemented

        --eventlet_server
        eventlet_server_public_port = { type = "number", default = 5000 }, --not implemented


        redis_port = { type = "number", default = 6379 },
        redis_host = { type = "string", default = '127.0.0.1' },
        redis_timeout = { type = "number", default = 2000 },
        redis_password = { type = "string", default = '' },

        identity_provider = {type = "string", enum = {"uuid", "fernet"}, default = "fernet"},
        max_active_fernet_keys = {type = "number", default = 3},

        --trust block
        trust_enabled = {type = "boolean", default = true},
        trust_allow_redelegation = {type = "boolean", default = true},
        trust_max_redelegation_count = {type = "number", default = 100} 
    },
    self_check = function(schema, conf, dao, is_updating)
        local red, err = redis.connect(conf)
        if err then
            return false, errors.schema(err)
        end

        return true
    end
}

