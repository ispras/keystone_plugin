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
    kutils.assert_dao_error(err, "role find_all")

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
    kutils.assert_dao_error(err, "role find_all")
    if next(temp) then
        return responses.send_HTTP_BAD_REQUEST("Role with specified name already exists in domain")
    end

    role = {
        id = utils.uuid(),
        domain_id = role.domain_id,
        name = role.name
    }

    local role, err = dao_factory.role:insert(role)
    kutils.assert_dao_error(err, "role insert")

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
    kutils.assert_dao_error(err, "role find")
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
    kutils.assert_dao_error(err, "role find")
    if not role then
        return responses.send_HTTP_BAD_REQUEST("Role is not found")
    end

    if self.params.role and self.params.role.name then
        local temp, err = dao_factory.role:find_all({name = self.params.role.name, domain_id = role.domain_id})
        kutils.assert_dao_error(err, "role find_all")
        if next(temp) then
            return responses.send_HTTP_BAD_REQUEST("Role with specified name is already exists in domain")
        end

        local _, err = dao_factory.role:update({name = self.params.role.name}, {id = role.id})
        kutils.assert_dao_error(err, "role update")
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
    kutils.assert_dao_error(err, "role find")
    if not role then
        return responses.send_HTTP_BAD_REQUEST("Role is not found")
    end

    local _, err = dao_factory.role:delete({id = role.id})
    kutils.assert_dao_error(err, "role delete")

    return responses.send_HTTP_NO_CONTENT()
end

local function list_role_assignments(self, dao_factory, type)
    local actor_id, target_id = self.params.actor_id, self.params.target_id
    if type and not (type == "UserProject" or type == "UserDomain" or type == "GroupProject" or type == "GroupDomain") and not actor_id or not target_id then
        return responses.send_HTTP_BAD_REQUEST("Incorrect type")
    end

    local assigns, err = dao_factory.assignment:find_all({actor_id = actor_id, target_id = target_id, type = type})
    kutils.assert_dao_error(err, "assignment find_all")

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

local function check_actor_target_role_id(dao_factory, actor_id, target_id, role_id, type)
    if type and not (type == "UserProject" or type == "UserDomain" or type == "GroupProject" or type == "GroupDomain") and not actor_id or not target_id then
        return "Incorrect type"
    end

    local temp, err = dao_factory.role:find({id = role_id})
    kutils.assert_dao_error(err, "role find")
    if not temp then
        return "No role found"
    end
    if type:match("User") then
        temp, err = dao_factory.user:find({id = actor_id})
        kutils.assert_dao_error(err, "user find")
        if not temp then
            return "No user found"
        end
    end
    if type:match("Group") then
        local temp, err = dao_factory.group:find({id = actor_id})
        kutils.assert_dao_error(err, "group find")
        if not temp then
            return "No group found"
        end
    end
    if type:match("Project") then
        local temp, err = dao_factory.project:find({id = target_id})
        kutils.assert_dao_error(err, "project find")
        if not temp then
            return "No project found"
        end
    end
    if type:match("Domain") then
        local temp, err = dao_factory.project:find({id = target_id})
        kutils.assert_dao_error(err, "project find")
        if not temp or not temp.is_domain then
            return "No domain found"
        end
    end

end

local function assign_role(self, dao_factory, type)
    local actor_id, target_id, role_id = self.params.actor_id, self.params.target_id, self.params.role_id

    local err = check_actor_target_role_id(dao_factory, actor_id, target_id, role_id, type)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local assign = {
        type = type,
        actor_id = actor_id,
        target_id = target_id,
        role_id = role_id,
        inherited = false
    }
    local _, err = dao_factory.assignment:insert(assign)
    kutils.assert_dao_error(err, "assignment insert")

    return responses.send_HTTP_NO_CONTENT()
end

local function check_assignment(self, dao_factory, type)
    local actor_id, target_id, role_id = self.params.actor_id, self.params.target_id, self.params.role_id

    local err = check_actor_target_role_id(dao_factory, actor_id, target_id, role_id, type)
    if err then
        return responses.send_HTTP_BAD_REQUEST()
    end

    local temp, err = dao_factory.assignment:find_all({type = type, actor_id = actor_id, target_id = target_id, role_id})
    kutils.assert_dao_error(err, "assignment find_all")
    if not next(temp) then
        return responses.send(210)
    end

    return responses.send_HTTP_NO_CONTENT()
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
    ["/v3/domains/:target_id/groups/:actor_id/roles"] = {
        GET = function(self, dao_factory)
            list_role_assignments(self, dao_factory, "GroupDomain")
        end
    },
    ["/v3/domains/:target_id/groups/:actor_id/roles/:role_id"] = {
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
    ["/v3/domains/:target_id/users/:actor_id/roles"] = {
        GET = function(self, dao_factory)
            list_role_assignments(self, dao_factory, "UserDomain")
        end
    },
    ["/v3/domains/:target_id/users/:actor_id/roles/:role_id"] = {
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
    ["/v3/projects/:target_id/groups/:actor_id/roles"] = {
        GET = function(self, dao_factory)
            list_role_assignments(self, dao_factory, "GroupProject")
        end
    },
    ["/v3/projects/:target_id/groups/:actor_id/roles/:role_id"] = {
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
    ["/v3/projects/:target_id/users/:actor_id/roles"] = {
        GET = function(self, dao_factory)
            list_role_assignments(self, dao_factory, "UserProject")
        end
    },
    ["/v3/projects/:target_id/users/:actor_id/roles/:role_id"] = {
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