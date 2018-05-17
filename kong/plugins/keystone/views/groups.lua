local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")
local cjson = require 'cjson'

local namespace_id

local function get_group_by_id_or_name(dao_factory, id_or_name)
    local group, err = dao_factory.group:find({id = id_or_name})
    kutils.assert_dao_error(err, "group find")
    if group then return group end
    local temp, err = dao_factory.group:find_all ({name = id_or_name, domain_id = namespace_id})
    kutils.assert_dao_error(err, "group find all")
    if temp[1] then return temp[1] end
    responses.send_HTTP_BAD_REQUEST("No group with id "..id_or_name)
end

local function get_user_by_id_or_name (dao_factory, id_or_name)
    local user, err = dao_factory.user:find({id = id_or_name})
    kutils.assert_dao_error(err, "user find")
    if user then return user.id end
    local temp, err = dao_factory.local_user:find_all ({name = id_or_name, domain_id = namespace_id})
    kutils.assert_dao_error(err, "local user find all")
    if temp[1] then return temp[1].user_id end
    local temp, err = dao_factory.nonlocal_user:find({ name = id_or_name, domain_id = namespace_id })
    kutils.assert_dao_error(err, "nonlocal user find")
    if temp then return temp.user_id end
    responses.send_HTTP_BAD_REQUEST("No user with id "..id_or_name)
end

local function list_groups(self, dao_factory)
    local args = (self.params.name or self.params.domain_id) and {name = self.params.name, domain_id = self.params.domain_id} or nil

    local resp = {
        links = {
            self = self:build_url(self.req.parsed_url.path),
            next = cjson.null,
            previous = cjson.null
        },
        groups = {}
    }


    local groups, err = dao_factory.group:find_all(args)
    kutils.assert_dao_error(err, "group:find_all")
    resp.groups = groups
    for i = 1, #groups do
        resp.groups[i].links = {
            self = self:build_url(self.req.parsed_url.path..'/'..groups[i].id)
        }
    end

    return responses.send_HTTP_OK(resp)
end

local function create_group(self, dao_factory)
    if not self.params.group or not self.params.group.name then
        responses.send_HTTP_BAD_REQUEST("No group object found in request")
    end
    local group = {
        id = utils.uuid(),
        description = self.params.group.description,
        domain_id = self.params.group.domain_id or 'default',
        name = self.params.group.name
    }
    local temp, err = dao_factory.group:find_all({name = group.name, domain_id = group.domain_id})
    kutils.assert_dao_error(err, "group:find_all")
    if next(temp) then
        return responses.send_HTTP_CONFLICT("Name is already used in domain")
    end
    local _, err = dao_factory.group:insert(group)
    kutils.assert_dao_error(err, "group:insert")
    local resp = {
        group = group
    }
    resp.group.links = {
        self = self:build_url(self.req.parsed_url.path..'/'..group.id)
    }
    return responses.send_HTTP_CREATED(resp)
end

local function get_group_info(self, dao_factory)
    local group = get_group_by_id_or_name(dao_factory, self.params.group_id)

    local resp = {
        group = group
    }
    resp.group.links = {
        self = self:build_url(self.req.parsed_url.path)
    }

    responses.send_HTTP_OK(resp)
end

local function update_group(self, dao_factory)
    if not self.params.group then
        return responses.send_HTTP_BAD_REQUEST("No group object found in request")
    end

    local group = get_group_by_id_or_name(dao_factory, self.params.group_id)

    local ugroup = {
        description = self.params.group.description,
        domain_id = self.params.group.domain_id,
        name = self.params.group.name
    }
    local temp, err = dao_factory.group:find_all({name = ugroup.name or group.name, domain_id = ugroup.domain_id or group.domain_id})
    if next(temp) then
        return responses.send_HTTP_CONFLICT("Name is already used in domain")
    end

    local resp = {
        group = {}
    }
    resp.group, err = dao_factory.group:update(ugroup, {id = group.id})
    kutils.assert_dao_error(err, "group:update")
    resp.group.links = {
        self = self:build_url(self.req.parsed_url.path)
    }

    responses.send_HTTP_OK(resp)
end

local function delete_group(self, dao_factory)
    local group = get_group_by_id_or_name(dao_factory, self.params.group_id)
    local group, err = dao_factory.group:delete({id = group.id})
    kutils.assert_dao_error(err, "group delete")

    responses.send_HTTP_NO_CONTENT()
end

local function list_group_users(self, dao_factory)
    local group = get_group_by_id_or_name(dao_factory, self.params.group_id)
    local user_group, err = dao_factory.user_group_membership:find_all({group_id = group.id})
    kutils.assert_dao_error(err, "user_group_membership:find_all")

    local resp = {
        links = {
            self = self:build_url(self.req.parsed_url.path),
            next = cjson.null,
            previous = cjson.null
        },
        users = {}
    }

    local password_expires_at, op = kutils.string_to_time(self.params.password_expires_at)

    for _, v in ipairs(user_group) do
        local user, err = dao_factory.user:find({id = v.user_id})
        kutils.assert_dao_error(err, "user:find")
        local uname, exp
        local temp, err = dao_factory.local_user:find_all({user_id = user.id})
        kutils.assert_dao_error(err, "local_user:find_all")
        local loc_user = temp[1]
        local fit = true
        if loc_user then
            uname = loc_user.name
            local passwd, err = dao_factory.password:find_all({local_user_id = loc_user.id})
            kutils.assert_dao_error(err, "password:find_all")
            exp = passwd[1] and passwd[1].expires_at
            if password_expires_at then
                if not exp or op == 'lt' and exp >= password_expires_at or
                        op == 'lte' and exp > password_expires_at or
                            op == 'gt' and exp <= password_expires_at or
                                op == 'gte' and exp < password_expires_at or
                                    op == 'eq' and exp ~= password_expires_at or
                                        op == 'neq' and exp == password_expires_at then
                    fit = false
                end
            end
        elseif password_expires_at then
            fit = false
        else
            local temp, err = dao_factory.nonlocal_user:find_all({user_id = user.id})
            kutils.assert_dao_error(err, "nonlocal_user:find_all")
            if next(temp) then
                uname = temp[1].name
            end
        end
        resp.users[#resp.users + 1] = fit and {
            domain_id = user.domain_id,
            description = user.description,
            enabled = kutils.bool(user.enabled),
            id = user.id,
            name = uname or cjson.null,
            links = {
                self = self:build_url("/v3/users/"..user.id)
            },
            password_expires_at = loc_user and kutils.time_to_string(exp)
        } or nil
    end

    responses.send_HTTP_OK(resp)
end

local function add_user_to_group(self, dao_factory)
    local group = get_group_by_id_or_name(dao_factory, self.params.group_id)
    local user_id = get_user_by_id_or_name(dao_factory, self.params.user_id)
    local _, err = dao_factory.user_group_membership:insert({user_id = user_id, group_id = group.id})
    kutils.assert_dao_error(err, "user_group_membership:insert")

    return 200
end

local function check_user_in_group(self, dao_factory)
    local group = get_group_by_id_or_name(dao_factory, self.params.group_id)
    local user_id = get_user_by_id_or_name(dao_factory, self.params.user_id)
    local temp, err = dao_factory.user_group_membership:find({user_id = user_id, group_id = group.id})
    kutils.assert_dao_error(err, "user_group_membership:find")
    if not temp then
        responses.send_HTTP_BAD_REQUEST()
    end

    responses.send_HTTP_NO_CONTENT()
end

local function remove_user_from_group(self, dao_factory)
    local group = get_group_by_id_or_name(dao_factory, self.params.group_id)
    local user_id = get_user_by_id_or_name(dao_factory, self.params.user_id)
    local temp, err = dao_factory.user_group_membership:delete({user_id = user_id, group_id = group.id})
    kutils.assert_dao_error(err, "user_group_membership:delete")
    if not temp then
        responses.send_HTTP_BAD_REQUEST()
    end

    responses.send_HTTP_NO_CONTENT()
end

local routes = {
    ['/v3/groups'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_groups", dao_factory, self.params)
            list_groups(self, dao_factory)
        end,
        POST = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_group", dao_factory, self.params)
            create_group(self, dao_factory)
        end
    },
    ['/v3/groups/:group_id'] = {
        GET = function (self, dao_factory)
            namespace_id = policies.check(self.req.headers['X-Auth-Token'], "identity:get_group", dao_factory, self.params)
            get_group_info(self, dao_factory)
        end,
        PATCH = function (self, dao_factory)
            namespace_id = policies.check(self.req.headers['X-Auth-Token'], "identity:update_group", dao_factory, self.params)
            update_group(self, dao_factory)
        end,
        DELETE = function (self, dao_factory)
            namespace_id = policies.check(self.req.headers['X-Auth-Token'], "identity:delete_group", dao_factory, self.params)
            delete_group(self, dao_factory)
        end,
    },
    ['/v3/groups/:group_id/users'] = {
        GET = function (self, dao_factory)
            namespace_id = policies.check(self.req.headers['X-Auth-Token'], "identity:list_users_in_group", dao_factory, self.params)
            list_group_users(self, dao_factory)
        end
    },
    ['/v3/groups/:group_id/users/:user_id'] = {
        PUT = function (self, dao_factory)
            namespace_id = policies.check(self.req.headers['X-Auth-Token'], "identity:add_user_to_group", dao_factory, self.params)
            responses.send(add_user_to_group(self, dao_factory))
        end,
        HEAD = function (self, dao_factory)
            namespace_id = policies.check(self.req.headers['X-Auth-Token'], "identity:check_user_in_group", dao_factory, self.params)
            check_user_in_group(self, dao_factory)
        end,
        DELETE = function (self, dao_factory)
            namespace_id = policies.check(self.req.headers['X-Auth-Token'], "identity:remove_user_from_group", dao_factory, self.params)
            remove_user_from_group(self, dao_factory)
        end
    }
}

return {
    routes = routes,
    add_member = add_user_to_group
}