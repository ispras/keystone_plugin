local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local sha512 = require('sha512')
local kutils = require ("kong.plugins.keystone.utils")

local function auth_password(user, dao_factory)
    local upassword = user.password
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

    local passwd, err = dao_factory.password:find_all ({local_user_id = loc_user.id})
    if err then
        return {error = err, func = "dao_factory.password:find_all"}
    end
    passwd = passwd[1]
    if not sha512.verify(upassword, passwd.password) then
        return {message = "Incorrect password"}
    end

    if not domain then
        domain, err = dao_factory.project:find({id = user.domain_id})
        if err then
            return {error = err, func = "dao_factory.project:find"}
        end
    end

    return nil, user, domain, passwd
end

local function auth_password_unscoped(self, dao_factory)
    local user = self.params.auth.identity.password and self.params.auth.identity.password.user
    if not user then
        return responses.send_HTTP_BAD_REQUEST({message = "Authentication information is required"})
    end
    local err, user, domain, passwd = auth_password(user, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

--    local token, err = dao_factory.token:find_all({user_id = user.id})
--    if err then
--        return responses.send_HTTP_BAD_REQUEST({error = err,  func = "dao_factory.token:find_all"})
--    end
--    if not next(token) then
--        -- create new token
--    else
--        -- check token valid, expires
--        token = token[1]
--    end
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
            audit_ids = {token.id}, -- TODO
            issued_at = kutils.time_to_string(os.time())
        }
    }
    return responses.send_HTTP_CREATED(resp)
end

local function auth_password_scoped(self, dao_factory)
    local user = self.params.auth.identity.password and self.params.auth.identity.password.user
    if not user then
        return responses.send_HTTP_BAD_REQUEST({message = "Authentication information is required"})
    end
    local err, user, domain, passwd = auth_password(user, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local scope = self.params.auth.scope

    local resp = {

    }
    return responses.send_HTTP_CREATED(resp)
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