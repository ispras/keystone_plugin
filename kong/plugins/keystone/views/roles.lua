local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local sha512 = require('sha512')
local kutils = require ("kong.plugins.keystone.utils")

local function list_roles(self, dao_factory)
    local name = self.params.name
    local domain_id = self.params.domain_id

    local resp = {
        links = {
            self = self:build_url(self.req.parsed_url.path),
            next = "null",
            prev = "null"
        },
        roles = {}
    }
    local args = (name or domain_id) and {name = name, domain_id = domain_id} or nil
    local roles, err = dao_factory.role:find_all(args)
    if err then
        return responses.send_HTTP_CONFLICT({error = err, func = "dao_factory.role:find_all"})
    end

    for i = 1, #roles do
        resp.roles[i] = {
            id = roles[i].id,
            links = {
                self = self:build_url(self.req.parsed_url.path..roles[i].id)
            },
            name = roles[i].name,
            domain_id = roles[i].domain_id
        }
    end

    return responses.send_HTTP_OK(resp)
end

local function create_role(self, dao_factory)
    local role = self.params.role
    if not role or not role.name then
        return responses.send_HTTP_BAD_REQUEST("Specify role object with name field")
    end

    if not role.domain_id then
        role.domain_id = kutils.default_domain(dao_factory)
    end

    local temp, err = dao_factory.role:find_all(role)
    if err then
        return responses.send_HTTP_CONFLICT({error = err, func = "dao_factory.role:find_all"})
    end
    if next(temp) then
        return responses.send_HTTP_BAD_REQUEST("Role with specified name already exists in domain")
    end

    role = {
        id = utils.uuid(),
        domain_id = role.domain_id,
        name = role.name
    }

    local role, err = dao_factory.role:insert(role)
    if err then
        return responses.send_HTTP_CONFLICT({error = err, func = "dao_factory.role:insert"})
    end

    local resp = {
        role = role
    }
    resp.links = {
        self = self:build_url(self.req.parsed_url.path..role.id)
    }

    return responses.send_HTTP_CREATED(resp)
end

local function get_role_info(self, dao_factory)
    local role_id = self.params.role_id
    local role, err = dao_factory.role:find({id = role_id})
    if err then
        return responses.send_CONFLICT({error = err, func = "role find"})
    end
    if not role then
        return responses.send_HTTP_BAD_REQUEST("Role is not found")
    end

    local resp = {
        role = role
    }
    resp.role.links = {
        self = self:build_url(self.req.parsed_url.path..role.id)
    }

    return responses.send_HTTP_OK(resp)
end

local function update_role(self, dao_factory)
    local role_id = self.params.role_id
    local role, err = dao_factory.role:find({id = role_id})
    if err then
        return responses.send_CONFLICT({error = err, func = "role find"})
    end
    if not role then
        return responses.send_HTTP_BAD_REQUEST("Role is not found")
    end

    if self.params.role and self.params.role.name then
        local temp, err = dao_factory.role:find_all({name = self.params.role.name, domain_id = role.domain_id})
        if err then
            return responses.send_HTTP_CONFLICT({error = err, func = "role find_all"})
        end
        if next(temp) then
            return responses.send_HTTP_BAD_REQUEST("Role with specified name is already exists in domain")
        end

        local _, err = dao_factory.role:update({name = self.params.role.name}, {id = role.id})
        if err then
            return responses.send_HTTP_CONFLICT({error = err, func = "role update"})
        end
        role.name = self.params.role.name

    end

    local resp = {
        role = role
    }
    resp.role.links = {
        self = self:build_url(self.req.parsed_url.path..role.id)
    }

    return responses.send_HTTP_OK(resp)
end

local function delete_role(self, dao_factory)
    local role_id = self.params.role_id
    local role, err = dao_factory.role:find({id = role_id})
    if err then
        return responses.send_CONFLICT({error = err, func = "role find"})
    end
    if not role then
        return responses.send_HTTP_BAD_REQUEST("Role is not found")
    end

    local _, err = dao_factory.role:delete({id = role.id})
    if err then
        return responses.send_HTTP_CONFLICT({error = err, func = "role delete"})
    end

    return responses.send_HTTP_NO_CONTENT()
end

local function list_role_assignments(self, dao_factory, type)
    local actor_id, target_id
    if type == "UserProject" then
        actor_id = self.params.user_id
        target_id = self.params.project_id
    elseif type == "UserDomain" then
        actor_id = self.params.user_id
        target_id = self.params.domain_id
    elseif type == "GroupProject" then
        actor_id = self.params.group_id
        target_id = self.params.project_id
    elseif type == "GroupDomain" then
        actor_id = self.params.group_id
        target_id = self.params.domain_id
    end
    if type and not actor_id or not target_id then
        return responses.send_BAD_HTTP_REQUEST("Incorrect type")
    end

    local assigns, err = dao_factory.assignment:find_all({actor_id = actor_id, target_id = target_id, type = type})
    if err then
        return responses.send_HTTP_CONFLICT({error = err, func = "assgnment find_all"})
    end

    local resp = {
        links = {
            self = self:build_url(self.req.parsed_url.path),
            previous = "null",
            next = "null"
        },
        roles = {}
    }

    for i = 1, #assigns do
        local role, err = dao_factory.role:find({id = assigns[i].role_id})
        if err or not role then
            kutils.handle_dao_error(resp, err or "no role", "role find")
        end
        resp.roles[i] = {
            role = role
        }
        resp.roles[i].role.links = {
            self = self:build_url(self.req.parsed_url.path..role.id)
        }
    end

    return responses.send_HTTP_OK(resp)
end

local function assign_role(self, dao_factory, type)
    return ''
end

local function check_assignment(self, dao_factory, type)
    return ''
end

local function unassign_role(self, dao_factory, type)
    return ''
end

local function list_implied_roles(self, dao_factory)
    return ''
end

local function create_role_inference_rule(self, dao_factory)
    return ''
end

local function get_role_inference_rule(self, dao_factory)
    return ''
end

local function confirm_role_inference_rule(self, dao_factory)
    return ''
end

local function delete_role_inference_rule(self, dao_factory)
    return ''
end

local function list_role_inferences(self, dao_factory)
    return ''
end

return {
    ["/v3/roles/"] = {
        GET = function(self, dao_factory)
            list_roles(self, dao_factory)
        end,
        POST = function(self, dao_factory)
            create_role(self, dao_factory)
        end
    },
    ["/v3/roles/:role_id"] = {
        GET = function(self, dao_factory)
            get_role_info(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            update_role(self, dao_factory)
        end,
        DELETE = function (self, dao_factory)
            delete_role(self, dao_factory)
        end
    },
    ["/v3/domains/:domain_id/groups/:group_id/roles"] = {
        GET = function(self, dao_factory)
            list_role_assignments(self, dao_factory, "GroupDomain")
        end
    },
    ["/v3/domains/:domain_id/groups/:group_id/roles/:role_id"] = {
        PUT = function(self, dao_factory)
            assign_role(self, dao_factory, "GroupDomain")
        end,
        HEAD = function (self, dao_factory)
            check_assignment(self, dao_factory, "GroupDomain")
        end,
        DELETE = function(self, dao_factory)
            unassign_role(self, dao_factory, "GroupDomain")
        end
    },
    ["/v3/domains/:domain_id/users/:user_id/roles"] = {
        GET = function(self, dao_factory)
            list_role_assignments(self, dao_factory, "UserDomain")
        end
    },
    ["/v3/domains/:domain_id/users/:user_id/roles/:role_id"] = {
        PUT = function(self, dao_factory)
            assign_role(self, dao_factory, "UserDomain")
        end,
        HEAD = function (self, dao_factory)
            check_assignment(self, dao_factory, "UserDomain")
        end,
        DELETE = function(self, dao_factory)
            unassign_role(self, dao_factory, "UserDomain")
        end
    },
    ["/v3/projects/:project_id/groups/:group_id/roles"] = {
        GET = function(self, dao_factory)
            list_role_assignments(self, dao_factory, "GroupProject")
        end
    },
    ["/v3/projects/:project_id/groups/:group_id/roles/:role_id"] = {
        PUT = function(self, dao_factory)
            assign_role(self, dao_factory, "GroupProject")
        end,
        HEAD = function (self, dao_factory)
            check_assignment(self, dao_factory, "GroupProject")
        end,
        DELETE = function(self, dao_factory)
            unassign_role(self, dao_factory, "GroupProject")
        end
    },
    ["/v3/projects/:project_id/users/:user_id/roles"] = {
        GET = function(self, dao_factory)
            list_role_assignments(self, dao_factory, "UserProject")
        end
    },
    ["/v3/projects/:project_id/users/:user_id/roles/:role_id"] = {
        PUT = function(self, dao_factory)
            assign_role(self, dao_factory, "UserProject")
        end,
        HEAD = function (self, dao_factory)
            check_assignment(self, dao_factory, "UserProject")
        end,
        DELETE = function(self, dao_factory)
            unassign_role(self, dao_factory, "UserProject")
        end
    },
    ["/v3/roles/:prior_role_id/implies"] = {
        GET = function(self, dao_factory)
            list_implied_roles(self, dao_factory)
        end
    },
    ["/v3/roles/:prior_role_id/implies/:implies_role_id"] = {
        PUT = function(self, dao_factory)
            create_role_inference_rule(self, dao_factory)
        end,
        GET = function(self, dao_factory)
            get_role_inference_rule(self, dao_factory)
        end,
        HEAD = function(self, dao_factory)
            confirm_role_inference_rule(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            delete_role_inference_rule(self, dao_factory)
        end
    },
    ["/v3/role_assigments"] = {
        GET = function(self, dao_factory)
            list_role_assignments(self, dao_factory)
        end
    },
    ["/v3/role_inferences"] = {
        GET = function(self, dao_factory)
            list_role_inferences(self, dao_factory)
        end
    }

}