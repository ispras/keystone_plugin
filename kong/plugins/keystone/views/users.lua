local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local sha512 = require('sha512')
local kutils = require ("kong.plugins.keystone.utils")

local function list_users(self, dao_factory, helpers)
    local resp = {
        links = {
            next = "null",
            previous = "null",
            self = self:build_url(self.req.parsed_url.path)
        },
        users = {}
    }

    local domain_id = self.params.domain_id
    local enabled = kutils.bool(self.params.enabled)
    local idp_id = self.params.idp_id
    local name = self.params.name
    local password_expires_at = self.params.password_expires_at
    local protocol_id = self.params.protocol_id
    local unique_id = self.params.unique_id

    local args = ( domain_id ~= nil or enabled ~= nil ) and { domain_id = domain_id, enabled = enabled } or nil
    local users_info, err = dao_factory.user:find_all(args)
    kutils.assert_dao_error(err, "user:find_all")
    if not next(users_info) then
        return responses.send_HTTP_OK(resp)
    end

    local num = 0
    for i = 1, #users_info do
        local fit = true
        local id = users_info[i].id
        local fed_user, err = dao_factory.federated_user:find_all({user_id = id, idp_id = idp_id, protocol_id = protocol_id, unique_id = unique_id})
        if err then
            fit = false
            kutils.assert_dao_error(err, "dao_factory.federated_user:find_all")
        elseif idp_id or protocol_id or unique_id then
            if not next(fed_user) then
                fit = false
            end
        elseif fed_user[1] then
            users_info[i].idp_id = fed_user[1].idp_id
            users_info[i].protocol_id = fed_user[1].protocol_id
            users_info[i].unique_id = fed_user[1].unique_id
        else
            users_info[i].idp_id = "null"
            users_info[i].protocol_id = "null"
            users_info[i].unique_id = "null"
        end

        local temp1, err1 = dao_factory.local_user:find_all({user_id = id, name = name})
        local temp2, err2 = dao_factory.nonlocal_user:find_all({user_id = id, name = name})
        if err1 or err2 then
            fit = false
            kutils.assert_dao_error(err1, "local_user:find_all")
            kutils.assert_dao_error(err2, "nonlocal_user:find_all")
        elseif name then
            if not (next(temp1) or next(temp2)) then
                fit = false
            end
        elseif next(temp1) or next(temp2) then
            users_info[i].name = next(temp1) and temp1[1].name or temp2[1].name
        end

-- TODO password_expires_at={operator}:{timestamp}, no parsing by the operator
--        local temp, err = dao_factory.password:find_all({local_user_id = id, expires_at = password_expires_at})
        local temp, err = {}, nil
        if err then
                fit = false
                kutils.assert_dao_error(err, "dao_factory.password:find_all")
        elseif password_expires_at then
            if not next(temp) then
                fit = false
            end
        elseif next(temp) then
            users_info[i].password_expires_at = temp[1].expires_at
        else
            users_info[i].password_expires_at = "null"
        end

        if fit then
            num = num + 1
            resp.users[num] = {
                domain_id = users_info[i].domain_id,
                enabled = users_info[i].enabled,
                id = id,
                name = users_info[i].name,
                idp_id = users_info[i].idp_id,
                protocol_id = users_info[i].protocol_id,
                unique_id = users_info[i].unique_id,
                links = {
                    self = resp.links.self .. '/' .. id
                },
                password_expires_at = users_info[i].password_expires_at
            }
            if users_info[i].default_project_id then
                resp.users[num].default_project_id = users_info[i].default_project_id
--                resp.users[num].default_project_id = '029a3ae4-9950-459c-933e-c90876576ea3'
            else
                resp.users[num].default_project_id = users_info[i].project_id
            end
        end
    end

    return responses.send_HTTP_OK(resp)
end

local function check_user_domain(dao_factory, domain_id, uname)
    local temp, err = dao_factory.project:find({id = domain_id})
    kutils.assert_dao_error(err, "projects:find")
    if not temp or not temp.is_domain then
        return responses.send_HTTP_BAD_REQUEST("Invalid domain ID")
    end

    local temp, err = dao_factory.local_user:find_all({name = uname, domain_id = domain_id})
    kutils.assert_dao_error(err, "local_user:find_all")
    if next(temp) then
        return responses.send_HTTP_BAD_REQUEST("Local user with this name is already exists")
    end
    local temp, err = dao_factory.nonlocal_user:find({name = uname, domain_id = domain_id})
    kutils.assert_dao_error(err, "nonlocal_user:find")
    if temp then
        return responses.send_HTTP_BAD_REQUEST("Nonlocal user with this name is already exists")
    end

end

local function create_local_user(self, dao_factory)
    local user = self.params.user
    if not user.name then
        return responses.send_HTTP_BAD_REQUEST("User object must have name field")
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
    check_user_domain(dao_factory, loc_user.domain_id, loc_user.name)
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

    local resp = {
        user = {
            links = {
                self = self:build_url(self.req.parsed_url.path)..'/'..user.id
            },
            default_project_id = user.default_project_id,
            domain_id = user.domain_id,
            enabled = user.enabled,
            id = user.id,
            name = loc_user.name,
            password_expires_at = passwd.expires_at or "null"
        }
    }
    return resp
end

local function create_nonlocal_user(self, dao_factory)
    local user = self.params.user
    if not user.name then
        return responses.send_HTTP_BAD_REQUEST("User object must have name field")
    end

    user.id = utils.uuid()
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
    check_user_domain(dao_factory, nonloc_user.domain_id, nonloc_user.name)
    local _, err = dao_factory.nonlocal_user:insert(nonloc_user)
    kutils.assert_dao_error(err, "local_user:insert")
    local user, err = dao_factory.user:insert(user)
    if err then
        dao_factory.local_user:delete({id = nonloc_user.id})
        kutils.assert_dao_error(err, "user:insert")
    end

    local resp = {
        user = {
            links = {
                self = self:build_url(self.req.parsed_url.path)..'/'..user.id
            },
            default_project_id = user.default_project_id,
            domain_id = user.domain_id,
            enabled = user.enabled,
            id = user.id,
            name = nonloc_user.name,
            password_expires_at = "null"
        }
    }
    return resp
end

local function get_user_info(self, dao_factory)
    local user_id = self.params.user_id
    local user, err = dao_factory.user:find({id = user_id})
    kutils.assert_dao_error(err, "user find")
    if not user then
        return responses.send_HTTP_NOT_FOUND({message = "No user with id "..user_id})
    end

    local resp = {
        user = {
            links = {
                self = self:build_url(self.req.parsed_url.path)
            },
            default_project_id = user.default_project_id,
            domain_id = user.domain_id,
            enabled = kutils.bool(user.enabled),
            id = user.id,
            password_expires_at = "null"
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
        resp.user.password_expires_at = passwd.expires_at or "null"

    elseif next(nonloc_user) then
        resp.user.name = nonloc_user[1].name
    else
        return responses.send_HTTP_BAD_REQUEST({message = "No name found for user "..user_id})
    end

    return responses.send_HTTP_OK(resp)
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
        check_user_domain(dao_factory, user.domain_id, uupdate.name)
    end

    local loc_user, nonloc_user, err
    loc_user, err = dao_factory.local_user:find_all({user_id = user_id})
    kutils.assert_dao_error(err, "local_user:find_all")
    loc_user = loc_user[1]
    if loc_user then
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
            password_expires_at = passwd and passwd.expires_at or "null"
        }
    }

    return responses.send_HTTP_OK(resp)
end

local function delete_user(self, dao_factory)
    local resp = {}
    local user_id = self.params.user_id
    local temp, temp1, err1, err2, err3, err4, err5, err6, err7, err8, err9, err10, err11, err12, err13, err14
    local _, err = dao_factory.user:delete({id = user_id})
    kutils.assert_dao_error(err, "user delete")

        temp, err1 = dao_factory.credential:find_all({user_id = user_id})
        if not err1 then
            for i = 1, #temp do
                _, err2 = dao_factory.credential:delete({id = temp[i].id})
            end
        end

        temp, err3 = dao_factory.federated_user:find_all({user_id = user_id})
        if not err3 then
            for i = 1, #temp do
                _, err4 = dao_factory.federated_user:delete({id = temp[i].id})
            end
        end

        temp, err5 = dao_factory.local_user:find_all({user_id = user_id})
        if not err5 then
            for i = 1, #temp do
                _, err6 = dao_factory.local_user:delete({id = temp[i].id})
                temp1, err7 = dao_factory.password:find_all({local_user_id = temp[i].id})
                if not err7 then
                    for j = 1, #temp1 do
                        _, err8 = dao_factory.password:delete({id = temp1[i].id})
                    end
                end

            end
        end

        temp, err9 = dao_factory.nonlocal_user:find_all({user_id = user_id})
        if not err9 then
            for i = 1, #temp do
                _, err10 = dao_factory.nonlocal_user:delete({domain_id = temp[i].domain_id, name = temp[i].name})
            end
        end

        temp, err11 = dao_factory.user_group_membership:find_all({user_id = user_id})
        if not err11 then
            for i = 1, #temp do
                _, err12 = dao_factory.user_group_membership:delete({user_id = temp[i].user_id, group_id = temp[i].group_id})
            end
        end

        temp, err13 = dao_factory.user_option:find_all({user_id = user_id})
        if not err13 then
            for i = 1, #temp do
                _, err14 = dao_factory.user_option:delete({user_id = temp[i].user_id, group_id = temp[i].group_id})
            end
        end

        kutils.assert_dao_error(err1, "credential:find_all")
        kutils.assert_dao_error(err2, "credential:delete")
        kutils.assert_dao_error(err3, "federated_user:find_all")
        kutils.assert_dao_error(err4, "federated_user:delete")
        kutils.assert_dao_error(err5, "local_user:find_all")
        kutils.assert_dao_error(err6, "local_user:delete")
        kutils.assert_dao_error(err7, "password:find_all")
        kutils.assert_dao_error(err8, "password:delete")
        kutils.assert_dao_error(err9, "nonlocal_user:find_all")
        kutils.assert_dao_error(err10, "nonlocsl_user:delete")
        kutils.assert_dao_error(err11, "user_group_membership:find_all")
        kutils.assert_dao_error(err12, "user_group_membership:delete")
        kutils.assert_dao_error(err13, "user_option:find_all")
        kutils.assert_dao_error(err14, "user_option:delete")

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
            next = "null",
            previous = "null"
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
            next = "null",
            previous = "null"
        },
        projects = {}
    }

    local temp, err = dao_factory.assignment:find_all({type = "UserProject", actor_id = user.id})
    kutils.assert_dao_error(err, "assignment:find_all")

    for i = 1, #temp do
        if not kutils.has_id(resp.projects, temp[i].target_id) then
            local project, err = dao_factory.project:find({id = temp[i].target_id})
            kutils.assert_dao_error(err, "dao_factory.project:find")
            local index = #resp.projects + 1
            resp.projects[index] = {
                description = project.description or "null",
                domain_id = project.domain_id or "null",
                enabled = project.enabled or "null",
                id = project.id,
                links = {
                    self = self:build_url('/v3/projects/'..project.id)
                },
                name = project.name,
                parent_id = project.parent_id or "null"
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

return {
    ["/v3/users"] = {
        GET = function(self, dao_factory)
            list_users(self, dao_factory)
        end,
        POST = function(self, dao_factory)
            if self.params.user and self.params.user.password then
                return responses.send_HTTP_CREATED(create_local_user(self, dao_factory))
            elseif self.params.user then
                return responses.send_HTTP_CREATED(create_nonlocal_user(self, dao_factory))
            else
                return responses.send_HTTP_BAD_REQUEST("Specify user object")
            end
        end
    },
    ["/v3/users/:user_id"] = {
        GET = function(self, dao_factory)
            get_user_info(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            update_user(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            delete_user(self, dao_factory)
        end
    },
    ["/v3/users/:user_id/groups"] = {
        GET = function(self, dao_factory)
            list_user_groups(self, dao_factory)
        end
    },
    ["/v3/users/:user_id/projects"] = {
        GET = function(self, dao_factory)
            list_user_projects(self, dao_factory)
        end
    },
    ["/v3/users/:user_id/password"] = {
        POST = function(self, dao_factory)
            change_user_password(self, dao_factory)
        end
    }
}