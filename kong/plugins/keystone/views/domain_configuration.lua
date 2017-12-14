local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local sha512 = require("kong.plugins.keystone.sha512")
local kutils = require ("kong.plugins.keystone.utils")

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
            create_domain_configuration(self, dao_factory)
        end,
        GET = function(self, dao_factory)
            get_domain_configuration(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            update_domain_configuration(self, dao_factory)
        end,
        DELETE = function (self, dao_factory)
            delete_domain_configuration(self, dao_factory)
        end
    }
}

return routes