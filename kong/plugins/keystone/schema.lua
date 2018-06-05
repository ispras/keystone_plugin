local errors = require "kong.dao.errors"
local redis = require "kong.plugins.keystone.redis"

local function check_default_crypt_strenght(default_crypt_strength)
    if default_crypt_strength > 10000 or default_crypt_strength < 1000 then
        return false, "Minimum value for crypt_strength is 1000, maximum value is 10000"
    end

    return true
end

local function check_fernet_tokens_max_active_keys(fernet_tokens_max_active_keys)
    if fernet_tokens_max_active_keys < 1 then
        return false, "Minimum value for fernet_tokens_max_active_keys is 1"
    end

    return true
end

local function check_identity_max_password_length(identity_max_password_length)
    if identity_max_password_length > 4096 then
        return false, "Maximum value for fernet_tokens_max_active_keys is 4096"
    end

    return true
end

return {
    no_consumer = true,
    fields = {
        --default block
        default_crypt_strength = { type = "number", func = check_default_crypt_strenght, default = 10000 },
        default_public_endpoint = { type = "string", default = '' }, --not implemented
        default_admin_endpoint = { type = "string", default = '' }, --not implemented
        default_max_project_tree_depth = { type = "number", default = 5 }, --not implemented
        default_max_param_size = { type = "number", default = 64 }, --not implemented
        default_max_token_size = { type = "number", default = 255 }, --not implemented
        default_member_role_id = { type = "string", default = '9fe2ff9ee4384b1894a90878d3e92bab' }, --not implemented
        default_member_role_name = { type = "string", default = '_member_' }, --not implemented
        default_list_limit = { type = "number", default = -1 }, 

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


        --fernet_tokens block
        fernet_tokens_max_active_keys = {type = "number", func = check_fernet_tokens_max_active_keys, default = 3},

        --identity block
        identity_default_domain_id = { type = "string", default = 'default' }, --not implemented
        identity_max_password_length = { type = "number", func = check_identity_max_password_length, default = 4096 }, --not implemented

        --matchmaker_redis block
        matchmaker_redis_port = { type = "number", default = 6379 },
        matchmaker_redis_host = { type = "string", default = '127.0.0.1' },
        matchmaker_redis_wait_timeout = { type = "number", default = 2000 },
        matchmaker_redis_password = { type = "string", default = '' },

        --oslo_policy block
        oslo_policy_policy_file = { type = "string", default = 'policy.json' }, --not implemented
        oslo_policy_policy_default_rule = { type = "string", default = 'default' }, --not implemented
        oslo_policy_policy_dirs = { type = "string", default = 'policy.d' }, --not implemented

        --resource block
        resource_admin_project_domain_name = { type = "string", default = 'admin' }, --not implemented
        resource_admin_project_name = { type = "string", default = 'admin' }, --not implemented
        resource_project_name_url_safe = { type = "string", enum = {"off", "new", "strict"}, default = 'off' }, --not implemented
        resource_domain_name_url_safe = { type = "string", enum = {"off", "new", "strict"}, default = 'off' }, --not implemented

        --token block
        token_expiration = { type = "number", default = 3600 }, --not implemented
        token_provider = {type = "string", enum = {"uuid", "fernet"}, default = "fernet"},
        token_revoke_by_id = {type = "boolean", default = true}, --not implemented
        token_allow_rescope_scoped_token = {type = "boolean", default = true}, --not implemented

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

