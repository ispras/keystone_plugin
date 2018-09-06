local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local roles = require ("kong.plugins.keystone.views.roles")
local assignment = roles.assignment
local policies = require ("kong.plugins.keystone.policies")
local cjson = require 'cjson'

local function assign_inherited_role(self, dao_factory, type, enable)
    local code = assignment.check(self, dao_factory, type, false)
    if code ~= 204 then
        responses.send(code)
    end
    local projects, err = type:match("Domain") and dao_factory.project:find_all({ domain_id = self.params.domain_id }) or
            kutils.subtree(dao_factory, self.params.project_id)
    kutils.assert_dao_error(err, type:match("Domain") and "project:find_all" or "subtree")
    for _, v in ipairs(projects) do
        self.params.project_id = v.id
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
            next = cjson.null,
            previous = cjson.null
        },
        roles = {}
    }

    local projects, err = type:match("Domain") and dao_factory.project:find_all({ domain_id = self.params.domain_id }) or
            kutils.subtree(dao_factory, self.params.project_id)
    kutils.assert_dao_error(err, type:match("Domain") and "project:find_all" or "subtree")
    for _, project in ipairs(projects) do
        if not project.is_domain then
            self.params.project_id = project.id
            local temp = assignment.list(self, dao_factory, type:match("User") and "UserProject" or "GroupProject", true)
            for _, v in ipairs(temp.roles) do
                resp.roles[#resp.roles + 1] = v
            end
        end
    end

    return responses.send_HTTP_OK(resp)
end

local function check_assignment(self, dao_factory, type)
    local code = assignment.check(self, dao_factory, type, false)
    if code ~= 204 then
        responses.send(code)
    end
    local projects, err = type:match("Domain") and dao_factory.project:find_all({ domain_id = self.params.domain_id }) or
            kutils.subtree(dao_factory, self.params.project_id)
    kutils.assert_dao_error(err, type:match("Domain") and "project:find_all" or "subtree")

    self.params = {
        user = type:match("User") and {
            id = self.params.user_id
        },
        group = type:match("Group") and {
            id = self.params.group_id
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

    responses.send_HTTP_BAD_REQUEST()
end

local routes = {
    ['/v3/OS-INHERIT/domains/:domain_id/users/:user_id/roles/inherited_to_projects'] = {
        GET = function (self, dao_factory)
--            responses.send_HTTP_OK(assignment.list(self, dao_factory, "UserDomain", true))
            policies.check(self, dao_factory, "identity:list_inherited_roles")
            list_inherited_roles(self, dao_factory, "UserDomain")
        end
    },
    ['/v3/OS-INHERIT/domains/:domain_id/groups/:group_id/roles/inherited_to_projects'] = {
        GET = function (self, dao_factory)
--            responses.send_HTTP_OK(assignment.list(self, dao_factory, "GroupDomain", true))
            policies.check(self, dao_factory, "identity:list_inherited_roles")
            list_inherited_roles(self, dao_factory, "GroupDomain")
        end
    },
    ['/v3/OS-INHERIT/domains/:domain_id/users/:user_id/roles/:role_id/inherited_to_projects'] = {
        PUT = function (self, dao_factory)
            policies.check(self, dao_factory, "identity:assign_inherited_role")
            assign_inherited_role(self, dao_factory, "UserDomain", true)
        end,
        HEAD = function (self, dao_factory)
            policies.check(self, dao_factory, "identity:check_inherited_assignment")
            check_assignment(self, dao_factory, "UserDomain")
            responses.send_HTTP_NO_CONTENT()
        end,
        DELETE = function (self, dao_factory)
            policies.check(self, dao_factory, "identity:unassign_inherited_role")
            assign_inherited_role(self, dao_factory, "UserDomain", false)
        end
    },
    ['/v3/OS-INHERIT/domains/:domain_id/groups/:group_id/roles/:role_id/inherited_to_projects'] = {
        PUT = function (self, dao_factory)
            policies.check(self, dao_factory, "identity:assign_inherited_role")
            assign_inherited_role(self, dao_factory, "GroupDomain", true)
        end,
        HEAD = function (self, dao_factory)
            policies.check(self, dao_factory, "identity:check_inherited_assignment")
            check_assignment(self, dao_factory, "GroupDomain")
            responses.send_HTTP_NO_CONTENT()
        end,
        DELETE = function (self, dao_factory)
            policies.check(self, dao_factory, "identity:assign_inherited_role")
            assign_inherited_role(self, dao_factory, "GroupDomain", false)
        end
    },
    ['/v3/OS-INHERIT/projects/:project_id/users/:user_id/roles/:role_id/inherited_to_projects'] = {
        PUT = function(self, dao_factory)
            policies.check(self, dao_factory, "identity:assign_inherited_role")
            assign_inherited_role(self, dao_factory, "UserProject", true)
        end,
        HEAD = function (self, dao_factory)
            policies.check(self, dao_factory, "identity:check_inherited_assignment")
            check_assignment(self, dao_factory, "UserProject")
            responses.send_HTTP_NO_CONTENT()
        end,
        DELETE = function(self, dao_factory)
            policies.check(self, dao_factory, "identity:assign_inherited_role")
            assign_inherited_role(self, dao_factory, "UserProject", false)
        end
    },
    ['/v3/OS-INHERIT/projects/:project_id/groups/:group_id/roles/:role_id/inherited_to_projects'] = {
        PUT = function(self, dao_factory)
            policies.check(self, dao_factory, "identity:assign_inherited_role")
            assign_inherited_role(self, dao_factory, "GroupProject", true)
        end,
        HEAD = function (self, dao_factory)
            policies.check(self, dao_factory, "identity:check_inherited_assignment")
            check_assignment(self, dao_factory, "GroupProject")
            responses.send_HTTP_NO_CONTENT()
        end,
        DELETE = function(self, dao_factory)
            policies.check(self, dao_factory, "identity:assign_inherited_role")
            assign_inherited_role(self, dao_factory, "GroupProject", false)
        end
    }
}

return routes