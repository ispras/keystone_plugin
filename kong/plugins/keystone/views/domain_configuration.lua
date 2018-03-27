local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local sha512 = require("kong.plugins.keystone.sha512")
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")

local function get_default_configuration(self, dao_factory)
    return ''
end

local function get_default_configuration_for_group(self, dao_factory)
    return ''
end

local function get_default_option_for_group(self, dao_factory)
    return ''
end

local function get_domain_group_option_configuration(self, dao_factory)
    return ''
end

local function update_domain_group_option_configuration(self, dao_factory)
    return ''
end

local function delete_domain_group_option_configuration(self, dao_factory)
    return ''
end

local function get_domain_group_configuration(self, dao_factory)
    return ''
end

local function update_domain_group_configuration(self, dao_factory)
    return ''
end

local function delete_domain_group_configuration(self, dao_factory)
    return ''
end

local function create_domain_configuration(self, dao_factory)
    return ''
end

local function get_domain_configuration(self, dao_factory)
    return ''
end

local function update_domain_configuration(self, dao_factory)
    return ''
end

local function delete_domain_configuration(self, dao_factory)
    return ''
end

local routes = {
    ['/v3/domains/confid/default'] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_domain_config_default", dao_factory, self.params)
            get_default_configuration(self, dao_factory)
        end
    },
    ['/v3/domains/config/:group_id/default'] = {
        GET = function(self, dao_factory)
            get_default_configuration_for_group(self, dao_factory)
        end
    },
    ['/v3/domains/config/:group_id/:option_name/default'] = {
        GET = function(self, dao_factory)
            get_default_option_for_group(self, dao_factory)
        end
    },
    ['/v3/domains/:domain_id/config/:group_id/:option_name'] = {
        GET = function(self, dao_factory)
            get_domain_group_option_configuration(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            update_domain_group_option_configuration(self, dao_factory)
        end,
        DELETE = function (self, dao_factory)
            delete_domain_group_option_configuration(self, dao_factory)
        end
    },
    ['/v3/domains/:domain_id/config/:group_id'] = {
        GET = function(self, dao_factory)
            get_domain_group_configuration(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            update_domain_group_configuration(self, dao_factory)
        end,
        DELETE = function (self, dao_factory)
            delete_domain_group_configuration(self, dao_factory)
        end
    },
    ['/v3/domains/:domain_id/config'] = {
        PUT = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_domain_config", dao_factory, self.params)
            create_domain_configuration(self, dao_factory)
        end,
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_domain_config", dao_factory, self.params)
            get_domain_configuration(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:update_domain_config", dao_factory, self.params)
            update_domain_configuration(self, dao_factory)
        end,
        DELETE = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_domain_config", dao_factory, self.params)
            delete_domain_configuration(self, dao_factory)
        end
    }
}

return routes