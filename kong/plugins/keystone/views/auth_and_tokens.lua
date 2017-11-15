local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local sha512 = require('sha512')
local kutils = require ("kong.plugins.keystone.utils")

local function check_user(user, dao_factory)
    local loc_user, domain
    if not (user.id or user.name and (user.domain.name or user.domain.id)) then
        return {message = "User info is required"}
    else
        if user.id then
            local err
            user, err = dao_factory.user:find({id = user.id})
            if err then
                return {error = err, func = "dao_factory.user:find"}
            end
            local temp, err = dao_factory.local_user:find_all({user_id = user.id})
            if err then
                return {error = err, func = "dao_factory.local_user:find_all"}
            end
            if not next(temp) then
                return {message = "Requested user is not local"}
            end
            loc_user = temp[1]
        else
            if not user.domain.id then
                local temp, err = dao_factory.project:find_all({is_domain = true, name = user.domain.name})
                if err then
                    return {error = err, func = "dao_factory.project:find_all"}
                end
                if not next(temp) then
                    return {message = "Requested domain is not found, check domain name = "..user.domain.name}
                end
                domain = temp[1]
                user.domain.id = domain.id
            end

            local temp, err = dao_factory.local_user:find_all ({name = user.name, domain_id = user.domain.id})
            if err then
                return {error = err, func = "dao_factory.local_user:find_all"}
            end
            if not next(temp) then
                return {message = "Requested user is not found, check user name = "..user.name}
            end
            loc_user = temp[1]
            user, err = dao_factory.user:find({id = loc_user.user_id})
            if err then
                return {error = err, func = "dao_factory.user:find"}
            end
        end
    end

    if not domain then
        local err
        domain, err = dao_factory.project:find({id = user.domain_id})
        if err then
            return {error = err, func = "dao_factory.project:find"}
        end
    end

    return nil, user, domain, loc_user

end
local function check_password(upasswd, loc_user, dao_factory)
    local passwd, err = dao_factory.password:find_all ({local_user_id = loc_user.id})
    if err then
        return {error = err, func = "dao_factory.password:find_all"}
    end
    passwd = passwd[1]
    if not sha512.verify(upasswd, passwd.password) then
        return {message = "Incorrect password"}
    end

    return nil, passwd
end

local function check_scope(scope, dao_factory)
    local project, domain_name
    if scope.project and scope.domain then
        return {message = "Specify either domain or project"}
    end
    if scope.project then
        if scope.project.id then
            local temp, err = dao_factory.project:find({id = scope.project.id})
            if err then
                return {error = err, func = "dao_factory.project:find" }
            end
            if not temp then
                return {message = "No requsted project for scope found" }
            end
            project = temp
            local temp, err = dao_factory.project:find({id = project.domain_id})
            if err then
                return {erorr = err, func = "dao_factory.project:find" }
            end
            domain_name = temp[1].name
        elseif scope.project.name and scope.project.domain and (scope.project.domain.id or scope.project.domain.name) then
            if not scope.project.domain.id then
                local temp, err = dao_factory.project:find_all ({name = scope.project.domain.name, is_domain = true})
                if err then
                    return {error = err, func = "dao_factory.project:find_all" }
                end
                if not next(temp) then
                    return {message = "No domain whith specified name = "..scope.project.domain.name }
                end
                scope.project.domain.id = temp[1].id
            else
                local temp, err = dao_factory.project:find ({id = scope.project.domain.id})
                if err then
                    return {error = err, func = "dao_factory.project:find" }
                end
                scope.project.domain.name = temp.name
            end
            domain_name = scope.project.domain.name
            local temp, err = dao_factory.project:find_all({name = scope.project.name, domain_id = scope.project.domain.id})
            if err then
                return {error = err, func = "dao_factory.project:find_all" }
            end
            if not next(temp) then
                return {message = "No requested project found for scope" }
            end
            project = temp[1]
        else
            return {message = "Project needs to be identified unique" }
        end

    elseif scope.domain then
        if scope.domain.id then
            local temp, err = dao_factory.project:find({id = scope.domain.id})
            if err then
                return {error = err, func = "dao_factory.project:find" }
            end
            project = temp

        elseif scope.domain.name then
            local temp, err = dao_factory.project:find_all({name = scope.domain.name, is_domain = true})
            if err then
                return {error = err, func = "dao_factory.project:find_all" }
            end
            if not next(temp) then
                return {message = "No domain found with requested name" }
            end
            project = temp[1]
        else
            return {message = "Domain needs to be identified unique" }
        end

        if project.domain_id then
            local temp, err = dao_factory.project:find({id = project.domain_id})
            if err then
                return {error = err, func = "dao_factory.project:find" }
            end
            domain_name = temp.name
        end

    else
        return {message = "No domain or project requested for scope"}
    end

    return nil, project, domain_name
end

local function get_catalog(dao_factory)
    local catalog = {}
    local servs, err = dao_factory.service:find_all()
    if err then
        return {error = err, func = "dao_factory.service:find_all" }
    end
    for i = 1, #servs do
        catalog[i] = {
            endpoints = {},
            type = servs[i].type,
            id = servs[i].id,
            name = servs[i].name
        }
        local endps, err = dao_factory.endpoint:find_all({service_id = servs[i].id})
        if err then
            return {error = err, func = "dao_factory.endpoint:find_all" }
        end
        for j = 1, #endps do
            catalog[i].endpoints[j] = {
                region_id = endps[j].region_id or "null",
                url = endps[j].url,
                region = "null",
                interface = endps[j].interface,
                id = endps[j].id
            }
            if endps[j].region_id then
                local region, err = dao_factory.region:find({id = endps[j].region_id})
                if err then
                    return {error = err, func = "dao_factory.region:find" }
                end
                catalog[i].endpoints[j].region = region.description
            end
        end
    end

    return nil, catalog
end

local function auth_password_unscoped(self, dao_factory)
    local user = self.params.auth.identity.password and self.params.auth.identity.password.user
    if not user then
        return responses.send_HTTP_BAD_REQUEST({message = "Authentication information is required"})
    end
    local upasswd = user.password
    local err, user, domain, loc_user = check_user(user, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end
    local err, passwd = check_password(upasswd, loc_user, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local token = {
        id = utils.uuid(),
        valid = true,
        user_id = user.id
    }
    local token, err = dao_factory.token:insert(token)
    if err then
        return responses.send_HTTP_CONFLICT ({error = err, func = "dao_factory.token:insert"})
    end

    local resp = {
        token = {
            methods = {"password"},
            expires_at = kutils.time_to_string(token.expires),
            extras = token.extra,
            user = {
                domain = {
                    id = domain.id,
                    name = domain.name
                },
                id = user.id,
                name = user.name,
                password_expires_at = kutils.time_to_string(passwd.expires_at)
            },
            audit_ids = {utils.uuid()}, -- TODO
            issued_at = kutils.time_to_string(os.time())
        }
    }
    return responses.send_HTTP_CREATED(resp, {["X-Subject-Token"] = token.id})
end

local function auth_password_scoped(self, dao_factory)
    local user = self.params.auth.identity.password and self.params.auth.identity.password.user
    if not user then
        return responses.send_HTTP_BAD_REQUEST({message = "Authentication information is required"})
    end
    local upasswd = user.password
    local err, user, domain, loc_user = check_user(user, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end
    local err, passwd = check_password(upasswd, loc_user, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local scope = self.params.auth.scope
    local err, project, domain_name = check_scope(scope, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local roles --TODO list of roles specified by access_token or request_token?
    local temp, err = dao_factory.request_token:find_all ({requested_project_id = project.id, consumer_id = ""})
    if err then
        return responses.send_HTTP_BAD_REQUEST({error = err, func = "dao_factory.request_token:find_all"})
    end
    for i = 1, #temp do
        roles[i] = {
            id = temp[i].id,
            name = temp[i].id
        }
    end

    local token = {
        id = utils.uuid(),
        valid = true,
        user_id = user.id
    }
    local token, err = dao_factory.token:insert(token)
    if err then
        return responses.send_HTTP_CONFLICT ({error = err, func = "dao_factory.token:insert"})
    end

    local resp = {
        token = {
            methods = {"password"},
            roles = roles,
            expires_at = kutils.time_to_string(token.expires),
            project = {
                domain = {
                    id = project.domain_id or "null",
                    name = domain_name or "null"
                },
                id = project.id,
                name = project.name
            },
            is_domain = scope.domain and true or false,
            extras = token.extra,
            user = {
                domain = {
                    id = domain.id,
                    name = domain.name
                },
                id = user.id,
                name = user.name,
                password_expires_at = kutils.time_to_string(passwd.expires_at)
            },
            audit_ids = {utils.uuid()}, -- TODO
            issued_at = kutils.time_to_string(os.time())
        }
    }
    if not (self.params.nocatalog) then
        local err, catalog = get_catalog(dao_factory)
        if err then
            kutils.handle_dao_error(resp, err, "get_catalog")
        else
            resp.token.catalog = catalog
        end
    end

    return responses.send_HTTP_CREATED(resp, {["X-Subject-Token"] = token.id})
end

local function auth_token_unscoped(self, dao_factory)
    return ''
end

local function auth_token_scoped(self, dao_factory)
    return ''
end

local function get_token_info(self, dao_factory)
    return ''
end

local function check_token(self, dao_factory)
    return ''
end

local function revoke_token(self, dao_factory)
    return ''
end

local function get_service_catalog(self, dao_factory)
    return ''
end

local function get_project_scopes(self, dao_factory)
    return ''
end

local function get_domain_scopes(self, dao_factory)
    return ''
end

return {
    ["/v3/auth/tokens"] = {
        POST = function(self, dao_factory)
            if self.params.auth then
                if not self.params.auth.scope or self.params.auth.scope == "unscoped" then
                    if self.params.auth.identity and self.params.auth.identity.methods[1] == "token" then
                        auth_token_unscoped(self, dao_factory)
                    elseif self.params.auth.identity and self.params.auth.identity.methods[1] == "password" then
                        auth_password_unscoped(self, dao_factory)
                    else
                        return responses.send_HTTP_BAD_REQUEST()
                    end
                else
                    if self.params.auth.identity and self.params.auth.identity.methods[1] == "token" then
                        auth_token_scoped(self, dao_factory)
                    elseif self.params.auth.identity and self.params.auth.identity.methods[1] == "password" then
                        auth_password_scoped(self, dao_factory)
                    else
                        return responses.send_HTTP_BAD_REQUEST()
                    end
                end
            end
        end,
        GET = function(self, dao_factory)
            get_token_info(self, dao_factory)
        end,
        HEAD = function(self, dao_factory)
            check_token(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            revoke_token(self, dao_factory)
        end
    },
    ["/v3/auth/catalog"] = {
        GET = function(self, dao_factory)
            get_service_catalog(self, dao_factory)
        end
    },
    ["/v3/auth/projects"] = {
        GET = function(self, dao_factory)
            get_project_scopes(self, dao_factory)
        end
    },
    ["/v3/auth/domains"] = {
        GET = function(self, dao_factory)
            get_domain_scopes(self, dao_factory)
        end
    }
}