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

    return resp
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

    return resp
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

local function list_role_assignments_for_actor_on_target(self, dao_factory, type)
    local actor_id, target_id = self.params.actor_id, self.params.target_id
    if type and not (type == "UserProject" or type == "UserDomain" or type == "GroupProject" or type == "GroupDomain") and not actor_id or not target_id then
        return responses.send_HTTP_BAD_REQUEST("Incorrect type")
    end

    -- TODO check in cache

    local assigns, err = dao_factory.assignment:find_all({actor_id = actor_id, target_id = target_id, type = type}) --, inherited = false
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
        kutils.assert_dao_error(err, "role:find")
        if role then
            resp.roles[i] = role
            resp.roles[i].links = {
                self = self:build_url(self.req.parsed_url.path..role.id)
            }
        end
    end

    if type:match("User") then
        local user_groups, err = dao_factory.user_group_membership:find_all({user_id = actor_id})
        kutils.assert_dao_error(err, "user_group_membership:find_all")
        for _, user_group  in pairs(user_groups) do
            local assigns, err = dao_factory.assignment:find_all({actor_id = actor_id, target_id = target_id, type = type, inherited = false})
            kutils.assert_dao_error(err, "assignment find_all")
            for _, assign in pairs(assigns) do
                if not kutils.has_id(resp.roles, assign.role_id) then
                    local role, err = dao_factory.role:find({id = assign.role_id})
                    kutils.assert_dao_error(err, "role:find")
                    if role then
                        local index = #resp.roles + 1
                        resp.roles[index] = role
                        resp.roles[index].links = {
                            self = self:build_url(self.req.parsed_url.path..role.id)
                        }
                    end
                end
            end
        end
    end

    --TODO cache result
    return resp
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
        if temp.is_domain then
            return "Requested project is domain"
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
end

local function check_assignment(self, dao_factory, type)
    local actor_id, target_id, role_id = self.params.actor_id, self.params.target_id, self.params.role_id

    local err = check_actor_target_role_id(dao_factory, actor_id, target_id, role_id, type)
    if err then
        return responses.send_HTTP_BAD_REQUEST()
    end

    local temp, err = dao_factory.assignment:find({type = type, actor_id = actor_id, target_id = target_id, role_id = role_id, inherited = false})
    kutils.assert_dao_error(err, "assignment find")
    if temp then
        return
    elseif type:match("User") then
        local ugroups, err = dao_factory.user_group_membership:find_all({user_id = actor_id})
        for _, ugroup in pairs(ugroups) do
            local temp, err = dao_factory.assignment:find({type = type:match("Project") and "GroupProject" or "GroupDomain",
                actor_id = ugroup.group_id, target_id = target_id, role_id = role_id, inherited = false})
            kutils.assert_dao_error(err, "assignment:find")
            if temp then
                return
            end
        end
    end

    return responses.send_HTTP_NOT_FOUND()
end

local function unassign_role(self, dao_factory, type)
    local actor_id, target_id, role_id = self.params.actor_id, self.params.target_id, self.params.role_id

    local err = check_actor_target_role_id(dao_factory, actor_id, target_id, role_id, type)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local assign, err = dao_factory.assignment:find_all({type = type, actor_id = actor_id, target_id = target_id, role_id = role_id, inherited = false})
    kutils.assert_dao_error(err, "assignment find_all")
    for i = 1, #assign do
        local _, err = dao_factory.assignment:delete(assign[i])
        kutils.assert_dao_error(err, "assignment delete")
    end

    return responses.send_HTTP_NO_CONTENT()
end

local function list_implied_roles(self, dao_factory)
    local prior_role_id = self.params.prior_role_id
    local role, err = dao_factory.role:find({id = prior_role_id})
    kutils.assert_dao_error(err, "role find")
    if not role then
        return responses.send_HTTP_BAD_REQUEST("No role found")
    end

    local resp = {
        links = {
            self= self:build_url(self.req.parsed_url.path)
        },
        role_inference = {
            prior_role = {
                id = role.id,
                links = self:build_url("/v3/roles/"..role.id),
                name = role.name
            },
            implies = {}
        }
    }

    local implies, err = dao_factory.implied_role:find_all({prior_role_id = prior_role_id})
    kutils.assert_dao_error(err, "implied_role:find_all")

    for i = 1, #implies do
        local role, err = dao_factory.role:find({id = implies[i].implied_role_id})
        kutils.assert_dao_error(err, "role find")

        resp.role_reference.implies[i] = {
            id = role.id,
            links = self:build_url("/v3/roles/"..role.id),
            name = role.name
        }
    end

    return resp
end

local function get_role_inference_rule(self, dao_factory, if_create)
    local prior_role_id, implied_role_id = self.params.prior_role_id, self.params.implied_role_id
    local role, err = dao_factory.role:find({id = prior_role_id})
    kutils.assert_dao_error(err, "role find")
    if not role then
        return responses.send_HTTP_BAD_REQUEST("Prior role not found")
    end
    local resp = {
        links = {
            self= self:build_url(self.req.parsed_url.path)
        },
        role_inference = {
            prior_role = {
                id = role.id,
                links = self:build_url("/v3/roles/"..role.id),
                name = role.name
            },
            implies = {}
        }
    }
    local role, err = dao_factory.role:find({id = implied_role_id})
    kutils.assert_dao_error(err, "role find")
    if not role then
        return responses.send_HTTP_BAD_REQUEST("Implied role not found")
    end
    resp.role_reference.implies = {
        id = role.id,
        links = self:build_url("/v3/roles/"..role.id),
        name = role.name
    }

    if if_create then
        local _, err = dao_factory.implied_role:insert({prior_role_id = prior_role_id, implied_role_id = implied_role_id})
        kutils.assert_dao_error(err)
    end

    return resp
end

local function create_role_inference_rule(self, dao_factory)
    return responses.send_HTTP_CREATED(get_role_inference_rule(self, dao_factory, true))
end

local function confirm_role_inference_rule(self, dao_factory)
    local prior_role_id, implied_role_id = self.params.prior_role_id, self.params.implied_role_id
    local role, err = dao_factory.role:find({id = prior_role_id})
    kutils.assert_dao_error(err, "role find")
    if not role then
        return responses.send_HTTP_BAD_REQUEST()
    end

    local role, err = dao_factory.role:find({id = implied_role_id})
    kutils.assert_dao_error(err, "role find")
    if not role then
        return responses.send_HTTP_BAD_REQUEST()
    end

    local temp, err = dao_factory.implied_role:find({prior_role_id = prior_role_id, implied_role_id = implied_role_id})
    kutils.assert_dao_error(err, "implied_role find")
    if not temp then
        return responses.send_HTTP_NOT_FOUND()
    end

    return
end

local function delete_role_inference_rule(self, dao_factory)
    local prior_role_id, implied_role_id = self.params.prior_role_id, self.params.implied_role_id
    local role, err = dao_factory.role:find({id = prior_role_id})
    kutils.assert_dao_error(err, "role find")
    if not role then
        return responses.send_HTTP_BAD_REQUEST("Prior role not found")
    end

    local role, err = dao_factory.role:find({id = implied_role_id})
    kutils.assert_dao_error(err, "role find")
    if not role then
        return responses.send_HTTP_BAD_REQUEST("Implied role not found")
    end

    local _, err = dao_factory.implied_role:delete({prior_role_id = prior_role_id, implied_role_id = implied_role_id})
    kutils.assert_dao_error(err, "implied_role find")

    return responses.send_HTTP_NO_CONTENT()
end

local function fill_assignment(dao_factory, role_assignments, type, actor_id, target_id, role_id, include_names)
    local k = #role_assignments
    local assigns, err = dao_factory.assignment:find_all({type = type, actor_id = actor_id, target_id = target_id, role_id = role_id, inherited = false})
    kutils.assert_dao_error(err, "assignments find_all")
    for i = 1, #assigns do
        k = k + 1
        local name = {}
        if include_names and include_names ~= 0 then
            local temp, err = dao_factory.role:find({id = assigns[i].role_id})
            kutils.assert_dao_error(err, "role find")
            name.role = temp and temp.name
            temp, err = dao_factory.project:find({id = assigns[i].target_id})
            kutils.assert_dao_error(err, "project find")
            name.project = temp and temp.name
            if type:match("User") then
                temp, err = dao_factory.user:find({id = assigns[i].actor_id})
                kutils.assert_dao_error(err, "user find")
                name.user = temp and temp.name
            else
                temp, err = dao_factory.group:find({id = assigns[i].actor_id})
                kutils.assert_dao_error(err, "group find")
                name.group = temp and temp.name
            end
        end
        role_assignments[k] = {
            links = {
                assignment = "/v3"..(type:match("Project") and "/projects/" or "/domains/")..assigns[i].target_id..(type:match("User") and "/users/" or "/groups")..assigns[i].actor_id.."/roles/"..assigns[i].role_id
            },
            role = {
                id = assigns[i].role_id,
                name = name.role
            },
            scope = {
                project = type:match("Project") and {
                    id = assigns[i].target_id,
                    name = name.project
                },
                domain = type:match("Domain") and {
                    id = assigns[i].target_id,
                    name = name.project
                }
            },
            user = type:match("User") and {
                id = assigns[i].actor_id,
                name = name.user
            },
            group = type:match("Group") and {
                id = assigns[i].actor_id,
                name = name.group
            }
        }
    end
end

local function list_role_assignments(self, dao_factory, type)
    local effective = self.params.effective -- TODO not implemented
    local include_names = self.params.include_names
    local include_subtree = self.params.include_subtree
    local group_id = self.params.group and self.params.group.id
    local role_id = self.params.role and self.params.role.id
    local project_id = self.params.scope and self.params.scope.project and self.params.scope.project.id
    local domain_id = self.params.scope and self.params.scope.domain and self.params.scope.domain.id
    local user_id = self.params.user and self.params.user.id

    local resp = {
        links = {
            self = self:build_url(self.req.parsed_url.path),
            previous = "null",
            next = "null"
        },
        role_assignments = {}
    }

    fill_assignment(dao_factory, resp.role_assignments, "UserProject", user_id, project_id, role_id, include_names)
    fill_assignment(dao_factory, resp.role_assignments, "UserDomain", user_id, domain_id, role_id, include_names)
    fill_assignment(dao_factory, resp.role_assignments, "GroupProject", group_id, project_id, role_id, include_names)
    fill_assignment(dao_factory, resp.role_assignments, "GroupDomain", group_id, domain_id, role_id, include_names)

    for i = 1, #resp.role_assignments do
        resp.role_assignments[i].links.assignment = self:build_url(resp.role_assignments[i].links.assignment)
    end

    if include_subtree and include_subtree ~= 0 and project_id then
        local subtree = {}
        local parent_id = project_id
        local a = 0
        while parent_id do
            local projects, err = dao_factory.project:find_all ({parent_id = parent_id})
            kutils.assert_dao_error(err, "project find_all")
            for j = 1, #projects do
                local index = #subtree + 1
                subtree[index] = {
                    id = projects[j].id,
                    name = include_names and projects[j].name
                }
            end

            a = a + 1
            parent_id = subtree[a] and subtree[a].id
        end

        resp.subtree = subtree
    end

    return resp
end

local function list_role_inferences(self, dao_factory)
    local resp = {
        links = {
            self = self:build_url(self.req.parsed_url.path)
        },
        role_inferences = {}
    }

    local role_inferences, err = dao_factory.implied_role:find_all()
    kutils.assert_dao_error(err, "implied_role:find_all")
    for i = 1, #role_inferences do
        local index = #resp.role_inferences + 1
        local prior_role_id = role_inferences[i].prior_role_id
        resp.role_inferences[index] = {
            prior_role = {
                id = prior_role_id
            },
            implies = {}
        }
        while true do
            local j = kutils.has_id(role_inferences, prior_role_id, "prior_role_id")
            if not j then
                break
            end
            local ind = #resp.role_inferences[index].implies +1
            resp.role_inferences[index].implies[ind] = {
                id = role_inferences[j].implied_role_id
            }
            role_inferences[j] = nil
        end
    end

    for i = 1, #resp.role_inferences do
        local role, err = dao_factory.role:find({id = resp.role_inferences[i].prior_role.id})
        kutils.assert_dao_error(err, "role find")
        resp.role_inferences[i].prior_role.name = role.name
        resp.role_inferences[i].prior_role.links = {
            self = self:build_url("/v3/roles/"..role.id)
        }
        for j = 1, #resp.role_inferences[i].implies do
            local role, err = dao_factory.role:find({id = resp.role_inferences[i].implies[j].id})
            kutils.assert_dao_error(err, "role find")
            resp.role_inferences[i].implies[j].name = role.name
            resp.role_inferences[i].implies[j].links = {
                self = self:build_url("/v3/roles/"..role.id)
            }
        end
    end

    return resp
end
local Role = {
    list = list_roles,
    get_info = get_role_info
}

local Assignment = {
    list = list_role_assignments_for_actor_on_target,
    list_all = list_role_assignments,
    check = check_assignment,
    assign = assign_role
}
local Inference_rule = {
    list = list_implied_roles,
    get_info = get_role_inference_rule,
    check = confirm_role_inference_rule,
    list_all = list_role_inferences
}
local routes = {
    ["/v3/roles/"] = {
        GET = function(self, dao_factory)
            responses.send_HTTP_OK(list_roles(self, dao_factory))
        end,
        POST = function(self, dao_factory)
            create_role(self, dao_factory)
        end
    },
    ["/v3/roles/:role_id"] = {
        GET = function(self, dao_factory)
            responses.send_HTTP_OK(get_role_info(self, dao_factory))
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
            responses.send_HTTP_OK(list_role_assignments_for_actor_on_target(self, dao_factory, "GroupDomain"))
        end
    },
    ["/v3/domains/:target_id/groups/:actor_id/roles/:role_id"] = {
        PUT = function(self, dao_factory)
            assign_role(self, dao_factory, "GroupDomain")
            responses.send_HTTP_NO_CONTENT()
        end,
        HEAD = function (self, dao_factory)
            responses.send_HTTP_NO_CONTENT(check_assignment(self, dao_factory, "GroupDomain"))
        end,
        DELETE = function(self, dao_factory)
            unassign_role(self, dao_factory, "GroupDomain")
        end
    },
    ["/v3/domains/:target_id/users/:actor_id/roles"] = {
        GET = function(self, dao_factory)
            responses.send_HTTP_OK(list_role_assignments_for_actor_on_target(self, dao_factory, "UserDomain"))
        end
    },
    ["/v3/domains/:target_id/users/:actor_id/roles/:role_id"] = {
        PUT = function(self, dao_factory)
            assign_role(self, dao_factory, "UserDomain")
            responses.send_HTTP_NO_CONTENT()
        end,
        HEAD = function (self, dao_factory)
            responses.send_HTTP_NO_CONTENT(check_assignment(self, dao_factory, "UserDomain"))
        end,
        DELETE = function(self, dao_factory)
            unassign_role(self, dao_factory, "UserDomain")
        end
    },
    ["/v3/projects/:target_id/groups/:actor_id/roles"] = {
        GET = function(self, dao_factory)
            responses.send_HTTP_OK(list_role_assignments_for_actor_on_target(self, dao_factory, "GroupProject"))
        end
    },
    ["/v3/projects/:target_id/groups/:actor_id/roles/:role_id"] = {
        PUT = function(self, dao_factory)
            assign_role(self, dao_factory, "GroupProject")
            responses.send_HTTP_NO_CONTENT()
        end,
        HEAD = function (self, dao_factory)
            responses.send_HTTP_NO_CONTENT(check_assignment(self, dao_factory, "GroupProject"))
        end,
        DELETE = function(self, dao_factory)
            unassign_role(self, dao_factory, "GroupProject")
        end
    },
    ["/v3/projects/:target_id/users/:actor_id/roles"] = {
        GET = function(self, dao_factory)
            responses.send_HTTP_OK(list_role_assignments_for_actor_on_target(self, dao_factory, "UserProject"))
        end
    },
    ["/v3/projects/:target_id/users/:actor_id/roles/:role_id"] = {
        PUT = function(self, dao_factory)
            assign_role(self, dao_factory, "UserProject")
            responses.send_HTTP_NO_CONTENT()
        end,
        HEAD = function (self, dao_factory)
            responses.send_HTTP_NO_CONTENT(check_assignment(self, dao_factory, "UserProject"))
        end,
        DELETE = function(self, dao_factory)
            unassign_role(self, dao_factory, "UserProject")
        end
    },
    ["/v3/roles/:prior_role_id/implies"] = {
        GET = function(self, dao_factory)
            responses.send_HTTP_OK(list_implied_roles(self, dao_factory))
        end
    },
    ["/v3/roles/:prior_role_id/implies/:implied_role_id"] = {
        PUT = function(self, dao_factory)
            create_role_inference_rule(self, dao_factory)
        end,
        GET = function(self, dao_factory)
            responses.send_HTTP_OK(get_role_inference_rule(self, dao_factory))
        end,
        HEAD = function(self, dao_factory)
            responses.send_HTTP_NO_CONTENT(confirm_role_inference_rule(self, dao_factory))
        end,
        DELETE = function(self, dao_factory)
            delete_role_inference_rule(self, dao_factory)
        end
    },
    ["/v3/role_assigments"] = {
        GET = function(self, dao_factory)
            responses.send_HTTP_OK(list_role_assignments(self, dao_factory))
        end
    },
    ["/v3/role_inferences"] = {
        GET = function(self, dao_factory)
            responses.send_HTTP_OK(list_role_inferences(self, dao_factory))
        end
    }
}

return {routes = routes, roles = Role, assignment = Assignment, inference_rule = Inference_rule}