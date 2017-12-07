local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local sha512 = require('sha512')
local kutils = require ("kong.plugins.keystone.utils")
local roles = require ("kong.plugins.keystone.views.roles")
local assignment = roles.assignment

local function assign_inherited_role(self, dao_factory, type, enable)
    assignment.check(self, dao_factory, type, false)
    local projects, err = type:match("Domain") and dao_factory.project:find_all({ domain_id = self.params.target_id }) or
            kutils.subtree(dao_factory, self.params.target_id)
    kutils.assert_dao_error(err, type:match("Domain") and "project:find_all" or "subtree")
    for _, v in ipairs(projects) do
        self.params.target_id = v.id
        if not v.is_domain then
            if enable then
                assignment.assign(self, dao_factory, (type:match("User") and "User" or "Group").."Project", true, true)
            else
                assignment.unassign(self, dao_factory, (type:match("User") and "User" or "Group").."Project", true, true)
            end
        end
    end

    return responses.send_HTTP_NO_CONTENT()
end

local function list_inherited_roles(self, dao_factory, type)
    local resp = {
        links = {
            self = self:build_url(self.req.parsed_url.path),
            next = "null",
            previous = "null"
        },
        roles = {}
    }

    local projects, err = type:match("Domain") and dao_factory.project:find_all({ domain_id = self.params.target_id }) or
            kutils.subtree(dao_factory, self.params.target_id)
    kutils.assert_dao_error(err, type:match("Domain") and "project:find_all" or "subtree")
    for _, project in ipairs(projects) do
        if not project.is_domain then
            self.params.target_id = project.id
            local temp = assignment.list(self, dao_factory, type:match("User") and "UserProject" or "GroupProject", true)
            for _, v in ipairs(temp.roles) do
                resp.roles[#resp.roles + 1] = v
            end
        end
    end

    return responses.send_HTTP_OK(resp)
end

local function check_assignment(self, dao_factory, type)
    assignment.check(self, dao_factory, type, false)
    local projects, err = type:match("Domain") and dao_factory.project:find_all({ domain_id = self.params.target_id }) or
            kutils.subtree(dao_factory, self.params.target_id)
    kutils.assert_dao_error(err, type:match("Domain") and "project:find_all" or "subtree")

    self.params = {
        user = type:match("User") and {
            id = self.params.actor_id
        },
        group = type:match("Group") and {
            id = self.params.actor_id
        },
        role = {
            id = self.params.role_id
        },
        scope = {
            ['OS-INHERIT'] = {
                inherited_to = 'projects'
            }
        }
    }
    local temp = assignment.list_all(self, dao_factory)
    for _, v in ipairs(temp.role_assignments) do
        if kutils.has_id(projects, v.scope.project.id) then
            return
        end
    end

    responses.send_HTTP_NOT_FOUND()
end

local routes = {
    ['/v3/OS-INHERIT/domains/:target_id/users/:actor_id/roles/inherited_to_projects'] = {
        GET = function (self, dao_factory)
--            responses.send_HTTP_OK(assignment.list(self, dao_factory, "UserDomain", true))
            list_inherited_roles(self, dao_factory, "UserDomain")
        end
    },
    ['/v3/OS-INHERIT/domains/:target_id/groups/:actor_id/roles/inherited_to_projects'] = {
        GET = function (self, dao_factory)
--            responses.send_HTTP_OK(assignment.list(self, dao_factory, "GroupDomain", true))
            list_inherited_roles(self, dao_factory, "GroupDomain")
        end
    },
    ['/v3/OS-INHERIT/domains/:target_id/users/:actor_id/roles/:role_id/inherited_to_projects'] = {
        PUT = function (self, dao_factory)
            assign_inherited_role(self, dao_factory, "UserDomain", true)
        end,
        HEAD = function (self, dao_factory)
            check_assignment(self, dao_factory, "UserDomain")
            responses.send_HTTP_NO_CONTENT()
        end,
        DELETE = function (self, dao_factory)
            assign_inherited_role(self, dao_factory, "UserDomain", false)
        end
    },
    ['/v3/OS-INHERIT/domains/:target_id/groups/:actor_id/roles/:role_id/inherited_to_projects'] = {
        PUT = function (self, dao_factory)
            assign_inherited_role(self, dao_factory, "GroupDomain", true)
        end,
        HEAD = function (self, dao_factory)
            check_assignment(self, dao_factory, "GroupDomain")
            responses.send_HTTP_NO_CONTENT()
        end,
        DELETE = function (self, dao_factory)
            assign_inherited_role(self, dao_factory, "GroupDomain", false)
        end
    },
    ['/v3/OS-INHERIT/projects/:target_id/users/:actor_id/roles/:role_id/inherited_to_projects'] = {
        PUT = function(self, dao_factory)
            assign_inherited_role(self, dao_factory, "UserProject", true)
        end,
        HEAD = function (self, dao_factory)
            check_assignment(self, dao_factory, "UserProject")
            responses.send_HTTP_NO_CONTENT()
        end,
        DELETE = function(self, dao_factory)
            assign_inherited_role(self, dao_factory, "UserProject", false)
        end
    },
    ['/v3/OS-INHERIT/projects/:target_id/groups/:actor_id/roles/:role_id/inherited_to_projects'] = {
        PUT = function(self, dao_factory)
            assign_inherited_role(self, dao_factory, "GroupProject", true)
        end,
        HEAD = function (self, dao_factory)
            check_assignment(self, dao_factory, "GroupProject")
            responses.send_HTTP_NO_CONTENT()
        end,
        DELETE = function(self, dao_factory)
            assign_inherited_role(self, dao_factory, "GroupProject", false)
        end
    }
}

return routes