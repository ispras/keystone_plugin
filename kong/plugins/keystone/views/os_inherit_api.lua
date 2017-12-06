local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local sha512 = require('sha512')
local kutils = require ("kong.plugins.keystone.utils")
local roles = require ("kong.plugins.keystone.views.roles")
local assignment = roles.assignment

local function assign_inherited_role(self, dao_factory, type)
    assignment.assign(self, dao_factory, type, true)
    return responses.send_HTTP_NO_CONTENT()
end

local function list_inherited_roles(self, dao_factory, type)
    assignment.list(self, dao_factory, type, true)
    return ''
end

local function check_assignment(self, dao_factory, type)
    assignment.check(self, dao_factory, type, true)
    return ''
end

local function unassign_inherited_role(self, dao_factory, type)
    assignment.unassign(self, dao_factory, type, true)
    return ''
end

local routes = {
    ['/v3/OS-INHERIT/domains/:target_id/users/:actor_id/roles/inherited_to_projects'] = {
        GET = function (self, dao_factory)
            list_inherited_roles(self, dao_factory, "UserDomain")
        end
    },
    ['/v3/OS-INHERIT/domains/:target_id/groups/:actor_id/roles/inherited_to_projects'] = {
        GET = function (self, dao_factory)
            list_inherited_roles(self, dao_factory, "GroupDomain")
        end
    },
    ['/v3/OS-INHERIT/domains/:target_id/users/:actor_id/roles/:role_id/inherited_to_projects'] = {
        PUT = function (self, dao_factory)
            assign_inherited_role(self, dao_factory, "UserDomain")
        end,
        HEAD = function (self, dao_factory)
            check_assignment(self, dao_factory, "UserDomain")
        end,
        DELETE = function (self, dao_factory)
            unassign_inherited_role(self, dao_factory, "UserDomain")
        end
    },
    ['/v3/OS-INHERIT/domains/:target_id/groups/:actor_id/roles/:role_id/inherited_to_projects'] = {
        PUT = function (self, dao_factory)
            assign_inherited_role(self, dao_factory, "GroupDomain")
        end,
        HEAD = function (self, dao_factory)
            check_assignment(self, dao_factory, "GroupDomain")
        end,
        DELETE = function (self, dao_factory)
            unassign_inherited_role(self, dao_factory, "GroupDomain")
        end
    },
    ['/v3/OS-INHERIT/projects/:target_id/users/:actor_id/roles/:role_id/inherited_to_projects'] = {
        PUT = function(self, dao_factory)
            assign_inherited_role(self, dao_factory, "UserProject")
        end,
        HEAD = function (self, dao_factory)
            check_assignment(self, dao_factory, "UserProject")
        end,
        DELETE = function(self, dao_factory)
            unassign_inherited_role(self, dao_factory, "UserProject")
        end
    },
    ['/v3/OS-INHERIT/projects/:target_id/groups/:actor_id/roles/:role_id/inherited_to_projects'] = {
        PUT = function(self, dao_factory)
            assign_inherited_role(self, dao_factory, "GroupProject")
        end,
        HEAD = function (self, dao_factory)
            check_assignment(self, dao_factory, "GroupProject")
        end,
        DELETE = function(self, dao_factory)
            unassign_inherited_role(self, dao_factory, "GroupProject")
        end
    }
}

return routes