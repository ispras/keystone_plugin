local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local sha512 = require("kong.plugins.keystone.sha512")
local kutils = require ("kong.plugins.keystone.utils")
local roles = require ("kong.plugins.keystone.views.roles")
local policies = require ("kong.plugins.keystone.policies")
local assignment = roles.assignment
local cjson = require "cjson"

local function user_fits(params, dao_factory, user_info)

    local domain_id = params.domain_id
    local enabled = kutils.bool(params.enabled)
    local idp_id = params.idp_id
    local name = params.name
    local password_expires_at, op = kutils.string_to_time(params.password_expires_at)
    local protocol_id = params.protocol_id
    local unique_id = params.unique_id

    local id = user_info.id
    local fed_user, err = dao_factory.federated_user:find_all({user_id = id, idp_id = idp_id, protocol_id = protocol_id, unique_id = unique_id})
    kutils.assert_dao_error(err, "dao_factory.federated_user:find_all")
    if idp_id or protocol_id or unique_id then
        if not next(fed_user) then
            return false
        end
    elseif fed_user[1] then
        user_info.idp_id = fed_user[1].idp_id
        user_info.protocol_id = fed_user[1].protocol_id
        user_info.unique_id = fed_user[1].unique_id
    else
        user_info.idp_id = cjson.null
        user_info.protocol_id = cjson.null
        user_info.unique_id = cjson.null
    end

    local temp1, err = dao_factory.local_user:find_all({user_id = id, name = name})
    kutils.assert_dao_error(err, "local_user:find_all")
    local loc_user = temp1[1]

    if loc_user then
        user_info.name = loc_user.name
        local temp, err = dao_factory.password:find_all({local_user_id = loc_user.id})
        kutils.assert_dao_error(err, "password:find_all")
        user_info.password_expires_at = kutils.time_to_string(temp[1].expires_at)
        if password_expires_at then
            local exp = temp[1].expires_at
            if not exp or op == 'lt' and exp >= password_expires_at or
                    op == 'lte' and exp > password_expires_at or
                        op == 'gt' and exp <= password_expires_at or
                            op == 'gte' and exp < password_expires_at or
                                op == 'eq' and exp ~= password_expires_at or
                                    op == 'neq' and exp == password_expires_at then
                return false
            end
        end
    elseif password_expires_at then
        return false
    else
        local temp, err = dao_factory.nonlocal_user:find_all({user_id = id, name = name})
        kutils.assert_dao_error(err, "nonlocal_user:find_all")
        user_info.name = temp[1] and temp[1].name
    end

    return true
end

local function list_users(self, dao_factory, helpers)
    local resp = {
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
        },
        users = {}
    }

    local args = { domain_id = self.params.domain_id, enabled = kutils.bool(self.params.enabled) }
    local users_info, err = dao_factory.user:find_all(next(args) and args or nil)
    kutils.assert_dao_error(err, "user:find_all")
    if not next(users_info) then
        return responses.send_HTTP_OK(resp)
    end

    local num = 0
    for _, user_info in ipairs(users_info) do
        if user_fits(self.params, dao_factory, user_info) then
            num = num + 1
            resp.users[num] = {
                domain_id = user_info.domain_id,
                enabled = user_info.enabled,
                id = user_info.id,
                name = user_info.name or cjson.null,
                idp_id = user_info.idp_id,
                protocol_id = user_info.protocol_id,
                unique_id = user_info.unique_id,
                links = {
                    self = resp.links.self .. user_info.id
                },
                password_expires_at = user_info.password_expires_at,
                default_project_id = user_info.default_project_id
            }
        end
    end

    return responses.send_HTTP_OK(resp)
end

local function check_user_domain(dao_factory, domain_id, uname)
    local temp, err = dao_factory.project:find({id = domain_id})
    kutils.assert_dao_error(err, "projects:find")
    if not temp or not temp.is_domain then
        responses.send_HTTP_BAD_REQUEST("Invalid domain ID")
    end

    local temp, err = dao_factory.local_user:find_all({name = uname, domain_id = domain_id})
    kutils.assert_dao_error(err, "local_user:find_all")
    if next(temp) then
        return "Local user with this name is already exists"
    end
    local temp, err = dao_factory.nonlocal_user:find({name = uname, domain_id = domain_id})
    kutils.assert_dao_error(err, "nonlocal_user:find")
    if temp then
        return "Nonlocal user with this name is already exists"
    end

end

local function check_user_project(dao_factory, project_id)
    local temp, err = dao_factory.project:find({id = project_id})
    kutils.assert_dao_error(err, "projects:find")
    if not temp then
        return responses.send_HTTP_BAD_REQUEST("Invalid default project ID")
    end

end

local function assign_default_role(dao_factory, user)
    local self = {}
    self.params = {
        user_id = user.id,
        domain_id = user.domain_id,
        role_id = kutils.default_role(dao_factory)
    }
    assignment.assign(self, dao_factory, "UserDomain", false, true)

    if user.default_project_id then
        local self = {}
        self.params = {
            user_id = user.id,
            project_id = user.default_project_id,
            role_id = kutils.default_role(dao_factory)
        }
        assignment.assign(self, dao_factory, "UserProject", false, true)
    end

end

local function create_local_user(self, dao_factory)
    local user = self.params.user
    if not user.name then
        responses.send_HTTP_BAD_REQUEST("User object must have name field")
    end

    user.id = utils.uuid()
    local created_time = os.time()
    local loc_user = {
        id = utils.uuid(),
        user_id = user.id,
        domain_id = user.domain_id or kutils.default_domain(dao_factory),
        name = user.name
    }
    local passwd = {
        id = utils.uuid(),
        local_user_id = loc_user.id,
        password = sha512.crypt(user.password),
        created_at = created_time
    }
    local user = {
        id = user.id,
        enabled = user.enabled,
        default_project_id = user.default_project_id,
        created_at = created_time,
        domain_id = loc_user.domain_id
    }
    if not user.enabled then
        user.enabled = true
    end

    local err = check_user_domain(dao_factory, loc_user.domain_id, loc_user.name)
    if err then
        return 400, err
    end

    if user.default_project_id then
        check_user_project(dao_factory, user.default_project_id)
    end

    local passwd, err = dao_factory.password:insert(passwd)
    kutils.assert_dao_error(err, "password:insert")
    local _, err = dao_factory.local_user:insert(loc_user)
    if err then
        dao_factory.password:delete({id = passwd.id})
        kutils.assert_dao_error(err, "local_user:insert")
    end
    local user, err = dao_factory.user:insert(user)
    if err then
        dao_factory.local_user:delete({id = loc_user.id})
        dao_factory.password:delete({id = passwd.id})
        kutils.assert_dao_error(err, "user:insert")
    end

    assign_default_role(dao_factory, user)

    local resp = {
        user = {
            links = {
                self = self:build_url('/v3/users')..'/'..user.id
            },
            default_project_id = user.default_project_id,
            domain_id = user.domain_id,
            enabled = user.enabled,
            id = user.id,
            name = loc_user.name,
            password_expires_at = kutils.time_to_string(passwd.expires_at)
        }
    }

    return 201, resp
end

local function create_nonlocal_user(self, dao_factory)
    local user = self.params.user
    if not user.name then
        responses.send_HTTP_BAD_REQUEST("User object must have name field")
    end

    if user.id then
        local temp, err = dao_factory.user:find({id = user.id})
        kutils.assert_dao_error(err, "user find")
        if temp then
            error("attempt to create user with existed user_id")
        end
    else
        user.id = utils.uuid()
    end

    local created_time = os.time()
    local nonloc_user = {
        user_id = user.id,
        domain_id = user.domain_id or kutils.default_domain(dao_factory),
        name = user.name
    }
    local user = {
        id = user.id,
        enabled = user.enabled,
        default_project_id = user.default_project_id,
        created_at = created_time,
        domain_id = nonloc_user.domain_id
    }
    if not user.enabled then
        user.enabled = true
    end
    local err = check_user_domain(dao_factory, nonloc_user.domain_id, nonloc_user.name)
    if err then
        responses.send_HTTP_BAD_REQUEST(err)
    end

    if user.default_project_id then
        check_user_project(dao_factory, user.default_project_id)
    end

    local _, err = dao_factory.nonlocal_user:insert(nonloc_user)
    kutils.assert_dao_error(err, "local_user:insert")
    local user, err = dao_factory.user:insert(user)
    if err then
        dao_factory.local_user:delete({id = nonloc_user.id})
        kutils.assert_dao_error(err, "user:insert")
    end

    assign_default_role(dao_factory, user)

    local resp = {
        user = {
            links = {
                self = self:build_url('/v3/users')..'/'..user.id
            },
            default_project_id = user.default_project_id,
            domain_id = user.domain_id,
            enabled = user.enabled,
            id = user.id,
            name = nonloc_user.name
        }
    }
    return 201, resp
end

local function get_user_info(self, dao_factory)
    local user_id = self.params.user_id
    local user, err = dao_factory.user:find({id = user_id})
    kutils.assert_dao_error(err, "user find")
    if not user then
        responses.send_HTTP_NOT_FOUND({message = "No user with id "..user_id})
    end

    local resp = {
        user = {
            links = {
                self = self:build_url('/v3/users/'..user_id)
            },
            default_project_id = user.default_project_id,
            domain_id = user.domain_id,
            enabled = kutils.bool(user.enabled),
            id = user.id
        }
    }
    local loc_user, err = dao_factory.local_user:find_all({user_id = user_id})
    kutils.assert_dao_error(err, "local_user:find_all")
    local nonloc_user, err = dao_factory.nonlocal_user:find_all({user_id = user_id})
    kutils.assert_dao_error(err, "nonlocal_user:find_all")
    if next(loc_user) then
        resp.user.name = loc_user[1].name
        local passwd, err = dao_factory.password:find_all({local_user_id = loc_user[1].id})
        kutils.assert_dao_error( err, "password:find_all")
        resp.user.password_expires_at = kutils.time_to_string(passwd.expires_at)

    elseif next(nonloc_user) then
        resp.user.name = nonloc_user[1].name
    else
        responses.send_HTTP_BAD_REQUEST({message = "No name found for user "..user_id})
    end

    return 200, resp
end

local function update_user(self, dao_factory)
    local user_id = self.params.user_id
    local user, err = dao_factory.user:find({id = user_id})
    kutils.assert_dao_error(err, "user:find")
    if not user then
        return responses.send_HTTP_BAD_REQUEST({message = "No user found, check id = "..user_id})
    end

    local uupdate = self.params.user
    if not uupdate then
        return responses.send_HTTP_BAD_REQUEST({message = "No user object detected in request"})
    end
    if uupdate.name then
        local err = check_user_domain(dao_factory, user.domain_id, uupdate.name)
        if err then
            responses.send_HTTP_BAD_REQUEST(err)
        end
    end

    local loc_user, nonloc_user, err
    loc_user, err = dao_factory.local_user:find_all({user_id = user_id})
    kutils.assert_dao_error(err, "local_user:find_all")
    loc_user = loc_user[1]
    local loc = false
    if loc_user then
        loc = true
        if uupdate.name then
            loc_user, err = dao_factory.local_user:update({name = uupdate.name}, {id = loc_user.id})
            kutils.assert_dao_error(err, "local_user:update")
        end
    else
        nonloc_user, err = dao_factory.nonlocal_user:find_all({user_id = user_id})
        kutils.assert_dao_error(err, "nonlocal_user:find_all")
        nonloc_user = nonloc_user[1]
        if not nonloc_user then
            return responses.send_HTTP_CONFLICT("No local/nonlocal user")
        elseif uupdate.name then
            local temp, err = dao_factory.nonlocal_user:delete({name = nonloc_user.name, domain_id = nonloc_user.domain_id})
            kutils.assert_dao_error(err, "nonlocal_user:delete")
            nonloc_user.name = uupdate.name
            nonloc_user, err = dao_factory.nonlocal_user:insert(nonloc_user)
            kutils.assert_dao_error(err, "nonlocal_user:insert")
        end
    end

    local passwd
    if uupdate.password then
        passwd = {
            password= sha512.crypt(uupdate.password)
        }
    end

    uupdate = {
        default_project_id = uupdate.default_project_id,
        enabled = kutils.bool(uupdate.enabled)
    }

    if next(uupdate) then
        local err

        if uupdate.default_project_id then
            check_user_project(dao_factory, uupdate.default_project_id)
        end

        user, err = dao_factory.user:update(uupdate, {id = user_id})
        kutils.assert_dao_error(err, "user:update")
    end

    if passwd and loc_user then
        local temp, err = dao_factory.password:find_all ({local_user_id = loc_user.id})
        kutils.assert_dao_error(err, "password:find_all")
        passwd, err = dao_factory.password:update({password = passwd.password}, {id = temp[1].id})
        kutils.assert_dao_error(err, "password:update")
    elseif passwd and nonloc_user then
        local _, err = dao_factory.nonlocal_user:delete({name = nonloc_user.name, domain_id = nonloc_user.domain_id})
        kutils.assert_dao_error(err, "nonlocal_user:delete")
        local created_time = os.time()
        loc_user = {
            id = utils.uuid(),
            user_id = user.id,
            domain_id = user.domain_id,
            name = nonloc_user.name
        }
        passwd = {
            id = utils.uuid(),
            local_user_id = loc_user.id,
            password = passwd.password,
            created_at = created_time
        }
        passwd, err = dao_factory.password:insert(passwd)
        kutils.assert_dao_error(err, "password:insert")
        loc_user, err = dao_factory.local_user:insert(loc_user)
        if err then
            dao_factory.password:delete({passwd.id})
            kutils.assert_dao_error(err, "password:delete")
        end
        loc = true
    end

    local resp = {
        user = {
            links = {
                self = self:build_url(self.req.parsed_url.path)
            },
            default_project_id = user.default_project_id,
            domain_id = user.domain_id,
            enabled = user.enabled,
            id = user.id,
            name = loc_user and loc_user.name or nonloc_user.name,
            password_expires_at = loc and kutils.time_to_string(passwd.expires_at)
        }
    }

    return responses.send_HTTP_OK(resp)
end

local function delete_user(self, dao_factory)
    local resp = {}
    local user_id = self.params.user_id
    local temp, temp1, err1, err2, err3, err4, err5, err6, err7, err8, err9, err10, err11, err12, err13, err14, err15
    local _, err = dao_factory.user:delete({id = user_id})
    kutils.assert_dao_error(err, "user delete")

        temp = dao_factory.assignment:find_all({type = 'UserDomain', inherited = false, actor_id = user_id})
        for _, v in ipairs(temp) do
            dao_factory.assignment:delete(v)
        end
        temp = dao_factory.assignment:find_all({type = 'UserProject', inherited = false, actor_id = user_id})
        for _, v in ipairs(temp) do
            dao_factory.assignment:delete(v)
        end
        temp = dao_factory.assignment:find_all({type = 'UserDomain', inherited = true, actor_id = user_id})
        for _, v in ipairs(temp) do
            dao_factory.assignment:delete(v)
        end
        temp = dao_factory.assignment:find_all({type = 'UserProject', inherited = true, actor_id = user_id})
        for _, v in ipairs(temp) do
            dao_factory.assignment:delete(v)
        end
        temp, err1 = dao_factory.credential:find_all({user_id = user_id})
        if not err1 then
            for i = 1, #temp do
                _, err1 = dao_factory.credential:delete({id = temp[i].id})
            end
        end

        temp, err2 = dao_factory.federated_user:find_all({user_id = user_id})
        if not err2 then
            for i = 1, #temp do
                _, err2 = dao_factory.federated_user:delete({id = temp[i].id})
            end
        end

        temp, err3 = dao_factory.local_user:find_all({user_id = user_id})
        if not err3 then
            for i = 1, #temp do
                _, err3 = dao_factory.local_user:delete({id = temp[i].id})
                temp1, err3 = dao_factory.password:find_all({local_user_id = temp[i].id})
                if not err3 then
                    for j = 1, #temp1 do
                        _, err3 = dao_factory.password:delete({id = temp1[i].id})
                    end
                end

            end
        end

        temp, err4 = dao_factory.nonlocal_user:find_all({user_id = user_id})
        if not err4 then
            for i = 1, #temp do
                _, err4 = dao_factory.nonlocal_user:delete({domain_id = temp[i].domain_id, name = temp[i].name})
            end
        end

        temp, err5 = dao_factory.user_group_membership:find_all({user_id = user_id})
        if not err5 then
            for i = 1, #temp do
                _, err5 = dao_factory.user_group_membership:delete({user_id = temp[i].user_id, group_id = temp[i].group_id})
            end
        end

        temp, err6 = dao_factory.user_option:find_all({user_id = user_id})
        if not err6 then
            for i = 1, #temp do
                _, err6 = dao_factory.user_option:delete({user_id = temp[i].user_id, group_id = temp[i].group_id})
            end
        end

        temp, err7 = dao_factory.access_token:find_all({authorizing_user_id = user_id})
        if not err7 then
            for _, v in pairs(temp) do
                _, err7 = dao_factory.access_token:delete({id = v.id})
            end
        end

        kutils.assert_dao_error(err1, "credential:delete")
        kutils.assert_dao_error(err2, "federated_user:delete")
        kutils.assert_dao_error(err3, "local_user or password delete")
        kutils.assert_dao_error(err4, "nonlocsl_user:delete")
        kutils.assert_dao_error(err5, "user_group_membership:delete")
        kutils.assert_dao_error(err6, "user_option:delete")
        kutils.assert_dao_error(err7, "access token delete")

    return responses.send_HTTP_NO_CONTENT(resp)
end

local function list_user_groups(self, dao_factory)
    local user_id = self.params.user_id
    local user, err = dao_factory.user:find({id = user_id})
    kutils.assert_dao_error(err, "user find")
    if not user then
        return responses.send_HTTP_BAD_REQUEST({message = "No requested user in database"})
    end

    local resp = {
        links = {
            self = self:build_url(self.req.parsed_url.path),
            next = cjson.null,
            previous = cjson.null
        },
        groups = {}
    }
    local groups, err = dao_factory.user_group_membership:find_all({user_id = user_id})
    kutils.assert_dao_error(err, "user_group_membership:find_all")
    for i = 1, #groups do
        local group, err = dao_factory.group:find({id = groups[i].group_id})
        kutils.assert_dao_error(err, "group:find")
        resp.groups[i] = group
        resp.groups.extra = nil
        resp.groups[i].links.self =  self:build_url("/v3/groups/"..group.id)
    end

    return responses.send_HTTP_OK(resp)
end

local function list_user_projects(self, dao_factory)
    local user_id = self.params.user_id
    local user, err = dao_factory.user:find({id = user_id})
    kutils.assert_dao_error(err, "user find")
    if not user then
        return responses.send_HTTP_BAD_REQUEST({message = "No requested user in database"})
    end

    local resp = {
        links = {
            self = self:build_url(self.req.parsed_url.path),
            next = cjson.null,
            previous = cjson.null
        },
        projects = {}
    }

    local temp, err = dao_factory.assignment:find_all({type = "UserProject", actor_id = user.id, inherited = false})
    kutils.assert_dao_error(err, "assignment:find_all")

    for i = 1, #temp do
        if not kutils.has_id(resp.projects, temp[i].target_id) then
            local project, err = dao_factory.project:find({id = temp[i].target_id})
            kutils.assert_dao_error(err, "dao_factory.project:find")
            local index = #resp.projects + 1
            resp.projects[index] = {
                description = project.description or cjson.null,
                domain_id = project.domain_id or cjson.null,
                enabled = project.enabled or cjson.null,
                id = project.id,
                links = {
                    self = self:build_url('/v3/projects/'..project.id)
                },
                name = project.name,
                parent_id = project.parent_id or cjson.null
            }
        end
    end

    return responses.send_HTTP_OK(resp)
end

local function change_user_password(self, dao_factory)
    local user_id = self.params.user_id
    local user, err = dao_factory.user:find({id = user_id})
    kutils.assert_dao_error(err, "user:find")
    if not user then
        return responses.send_HTTP_BAD_REQUEST({message = "No requested user in database"})
    end

    local uupdate = self.params.user
    local temp, err = dao_factory.local_user:find_all({user_id = user_id})
    kutils.assert_dao_error(err, "local_user:find_all")
    local loc_user = temp[1]
    if not loc_user then
        return responses.send_HTTP_BAD_REQUEST({message = "User is not local"})
    end

    local temp, err = dao_factory.password:find_all({local_user_id = loc_user.id})
    kutils.assert_dao_error(err, "password find_all")
    local passwd = temp[1]
    if sha512.verify(uupdate.original_password, passwd.password) ~= true then
        return responses.send_HTTP_BAD_REQUEST({message = "Incorrect original_password"})
    end

    passwd.created_at = os.time()
    passwd.password = sha512.crypt(uupdate.password)
    local passwd, err = dao_factory.password:update(passwd, {id = passwd.id})
    kutils.assert_dao_error(err, "password:update")

    return responses.send_HTTP_NO_CONTENT()
end

local routes = {
    ["/v3/users"] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_users", dao_factory, self.params)
            list_users(self, dao_factory)
        end,
        POST = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_user", dao_factory, self.params)
            if self.params.user and self.params.user.name and self.params.user.name:match(".*@%a+%.%a+$") then
                responses.send_HTTP_BAD_REQUEST("Username shouldn't be an email")
            end
            if self.params.user and self.params.user.password then
                responses.send(create_local_user(self, dao_factory))
            elseif self.params.user then
                responses.send(create_nonlocal_user(self, dao_factory))
            else
                responses.send_HTTP_BAD_REQUEST("Specify user object")
            end
        end
    },
    ["/v3/users/:user_id"] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_user", dao_factory, self.params)
            responses.send(get_user_info(self, dao_factory))
        end,
        PATCH = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:update_user", dao_factory, self.params)
--            if self.params.user and self.params.user.name and self.params.user.name:match(".*@%a+%.%a+$") then
--                responses.send_HTTP_BAD_REQUEST("Username shouldn't be an email")
--            end
            update_user(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_user", dao_factory, self.params)
            delete_user(self, dao_factory)
        end
    },
    ["/v3/users/:user_id/groups"] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_user_groups", dao_factory, self.params)
            list_user_groups(self, dao_factory)
        end
    },
    ["/v3/users/:user_id/projects"] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_user_projects", dao_factory, self.params)
            list_user_projects(self, dao_factory)
        end
    },
    ["/v3/users/:user_id/password"] = {
        POST = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:change_password", dao_factory, self.params)
            change_user_password(self, dao_factory)
        end
    }
}

local User = {
    create_local = create_local_user,
    create_nonlocal = create_nonlocal_user,
    get = get_user_info
}

return {routes = routes, User = User}