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

    local resp = {
        domain = {
            id = domain.id,
            name = domain.name
        },
        id = user.id,
        name = user.name,
        password_expires_at = "null"
    }

    return nil, resp, loc_user.id

end
local function check_password(upasswd, loc_user_id, dao_factory)
    local passwd, err = dao_factory.password:find_all ({local_user_id = loc_user_id})
    if err then
        return {error = err, func = "dao_factory.password:find_all"}
    end
    passwd = passwd[1]
    if not sha512.verify(upasswd, passwd.password) then
        return {message = "Incorrect password"}
    end

    return nil, kutils.time_to_string(passwd.expires_at)
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

local function get_roles(domain_scoped, dao_factory, user_id, project_id)

    local roles = {}
    local temp, err = dao_factory.assignment:find_all ({type = domain_scoped and "UserDomain" or "UserProject", actor_id = user_id, target_id = project_id})
    if err then
        return {error = err, func = "dao_factory.request_token:find_all"}
    end
    for i = 1, #temp do
        local role, err = dao_factory.role:find({id = temp[i].role_id})
        if err then
                return {error = err, func = "dao_factory.role:find"}
        end
        roles[i] = {
            id = role.id,
            name = role.name
        }
    end

    return nil, roles

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

local function check_token_auth(token, dao_factory, allow_expired, validate)
    if not token or not token.id then
        return {message = "Token id is required"}
    end

    local temp, err = dao_factory.token:find({id = token.id})
    if err then
        return {error = err, func = "dao_factory.token:find"}
    end
    if not temp then
        return {message = "No token found" }
    end
    token = temp
    if not validate then
        if token.valid == false then
            return {message = "Token is not valid" }
        end
    elseif not token.valid then
        token, err = dao_factory.token:update({valid = true}, {id = token.id})
        if err then
            return {error = err, func = "dao_factory.token:update" }
        end
    end
    if not allow_expired then
        if token.expires and token.expires > os.time() then
            return {message = "Token is expired" }
        end
    end

end

local function check_token_user (token, dao_factory, allow_expired, validate)
    local err = check_token_auth(token, dao_factory, allow_expired, validate)
    if err then
        return err
    end

    local user, err = dao_factory.user:find({id = token.user_id})
    if err then
        return {error = err, func = "dao_factory.user:find" }
    end
    local domain, err = dao_factory.project:find({id = user.domain_id})
    if err then
        return {error = err, func = "dao_factory.project:find" }
    end
    local loc_user, err = dao_factory.local_user:find_all({user_id = user.id})
    if err then
        return {error = err, func = "dao_factory.local_user:find_all" }
    end
    local password, err = dao_factory.password:find_all({local_user_id = loc_user[1].id})
    if err then
        return {error = err, func = "dao_factory.password:find_all" }
    end

    local resp = {
        domain = {
            id = domain.id,
            name = domain.name
        },
        id = user.id,
        name = user.name,
        password_expires_at = kutils.time_to_string(password[1].expires_at)
    }
    return nil, resp
end


local function auth_password_unscoped(self, dao_factory)
    local user = self.params.auth.identity.password and self.params.auth.identity.password.user
    if not user then
        return responses.send_HTTP_BAD_REQUEST({message = "Authentication information is required"})
    end
    local upasswd = user.password
    local err, user, loc_user_id = check_user(user, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end
    err, user.password_expires_at = check_password(upasswd, loc_user_id, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local token = {
        id = utils.uuid(),
        valid = true,
        user_id = user.id,
        expires = os.time() + 24*60*60
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
            user = user,
            audit_ids = {utils.uuid()}, -- TODO
            issued_at = kutils.time_to_string(os.time())
        }
    }
    return responses.send_HTTP_CREATED(resp, {["X-Subject-Token"] = token.id})
end

local function auth_password_scoped(self, dao_factory)
    local resp = {}
    local user = self.params.auth.identity.password and self.params.auth.identity.password.user
    if not user then
        return responses.send_HTTP_BAD_REQUEST({message = "Authentication information is required"})
    end
    local upasswd = user.password
    local err, user, loc_user_id = check_user(user, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end
    err, user.password_expires_at = check_password(upasswd, loc_user_id, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local scope = self.params.auth.scope
    local err, project, domain_name = check_scope(scope, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local err, roles = get_roles(scope.domain and true or false, dao_factory, user.id, project.id)
    if err then
        kutils.handle_dao_error(resp, err, "get_roles")
    end

    local token = {
        id = utils.uuid(),
        valid = true,
        user_id = user.id,
        expires = os.time() + 24*60*60
    }
    local token, err = dao_factory.token:insert(token)
    if err then
        return responses.send_HTTP_CONFLICT ({error = err, func = "dao_factory.token:insert"})
    end

    resp = {
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
            user = user,
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
    local token = self.params.auth.identity.token
    local err, user = check_token_user(token, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local token = {
        id = utils.uuid(),
        valid = true,
        user_id = user.id,
        expires = os.time() + 24*60*60
    }
    local token, err = dao_factory.token:insert(token)
    if err then
        return responses.send_HTTP_CONFLICT ({error = err, func = "dao_factory.token:insert"})
    end

    local resp = {
        token = {
            methods = {"token"},
            expires_at = kutils.time_to_string(token.expires),
            extras = token.extra,
            user = user,
            audit_ids = {utils.uuid()}, -- TODO
            issued_at = kutils.time_to_string(os.time())
        }
    }

    return responses.send_HTTP_CREATED(resp, {["X-Subject-Token"] = token.id})
end

local function auth_token_scoped(self, dao_factory)
    local resp = {}

    local token = self.params.auth.identity.token
    local err, user = check_token_user(token, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local scope = self.params.auth.scope
    local err, project, domain_name = check_scope(scope, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local err, roles = get_roles(scope.domain and true or false, dao_factory, user.id, project.id)
    if err then
        kutils.handle_dao_error (resp, err, "get_roles")
    end

    local token = {
        id = utils.uuid(),
        valid = true,
        user_id = user.id,
        expires = os.time() + 24*60*60
    }
    local token, err = dao_factory.token:insert(token)
    if err then
        return responses.send_HTTP_CONFLICT ({error = err, func = "dao_factory.token:insert"})
    end

    resp = {
        token = {
            methods = {"token"},
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
            user = user,
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

local function get_token_info(self, dao_factory)
    local auth_token = self.req.headers["X-Auth-Token"]
    local subj_token = self.req.headers["X-Subject-Token"]

    local token = {
        id = auth_token
    }
    local err = check_token_auth(token, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end
    token = {
        id = subj_token
    }
    local err, user = check_token_user(token, dao_factory, self.params.allow_expired, true)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local resp = {
        token = {
            methods = {"token"},
            roles = {},
            expires_at = kutils.time_to_string(token.expires),
            project = {}, -- TODO
            extras = token.extra,
            user = user,
            audit_ids = {utils.uuid()}, -- TODO
            issued_at = kutils.time_to_string(os.time())
        }
    }
    local temp, err = dao_factory.assignments:find_all({actor_id = user.id})
    if err then
        kutils.handle_dao_error(resp, err, "dao_factory.assignments:find_all")
    end
    for i = 1, #temp do
        local role, err = dao_factory.role:find({id = temp[i].role_id})
        if err then
            kutils.handle_dao_error(resp, err, "dao_factory.role:find")
        else
            resp.token.roles[i] = {
                id = role.id,
                name = role.name
            }
        end

    end

    if not (self.params.nocatalog) then
        local err, catalog = get_catalog(dao_factory)
        if err then
            kutils.handle_dao_error(resp, err, "get_catalog")
        else
            resp.token.catalog = catalog
        end
    end

    return responses.send_HTTP_OK(resp, {["X-Subject-Token"] = token.id})
end

local function check_token(self, dao_factory)
    local auth_token = self.req.headers["X-Auth-Token"]
    local subj_token = self.req.headers["X-Subject-Token"]

    local token = {
        id = auth_token
    }
    local err = check_token_auth(token, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end
    token = {
        id = subj_token
    }
    local err = check_token_auth(token, dao_factory, self.params.allow_expired, true)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    -- TODO Identity API?

    return responses.send_HTTP_OK()
end

local function revoke_token(self, dao_factory)
    local subj_token = self.req.headers["X-Subject-Token"]
    if not subj_token then
        return responses.send_HTTP_BAD_REQUEST({message = "Specify header X-Subject-Token for token id"})
    end

    local token = {
        id = subj_token
    }
    local _, err = dao_factory.token:update({valid = false}, {id = token.id})
    if err then
        return responses.send_HTTP_CONFLICT({error = err, func = "dao_factory.token:find"})
    end

    return responses.send_HTTP_NO_CONTENT()
end

local function get_service_catalog(self, dao_factory)
    local auth_token = self.req.headers["X-Auth-Token"]
    local token = {
        id = auth_token
    }
    local err = check_token_auth(token, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local resp = {
        catalog = {},
        links = {
            next = "null",
            previous = "null",
            self = self:build_url(self.req.parsed_url.path)
        }
    }

    local err, catalog = get_catalog(dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end
    resp.catalog = catalog

    return responses.send_HTTP_OK(resp)
end

local function get_scopes(self, dao_factory, domain_scoped)
    local auth_token = self.req.headers["X-Auth-Token"]
    local token = {
        id = auth_token
    }
    local err, user = check_token_user(token, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    local resp = {
        links = {
            next = "null",
            previous = "null",
            self = self:build_url(self.req.parsed_url.path)
        }
    }
    local projects = {}
    local temp, err = dao_factory.assignment:find_all({type = domain_scoped and "UserDomain" or "UserProject", actor_id = user.id})
    if err then
        return responses.send_HTTP_BAD_REQUEST({error = err, func = "dao_factory.assignment:find_all"})
    end
    for i = 1, #temp do
        local project, err = dao_factory.project:find({id = temp[i].target_id})
        if err then
            kutils.handle_dao_error(resp, err, "dao_factory.project:find")
        else
            projects[i] = {
                id = project.id,
                links = {
                    self = self:build_url('/v3/projects/'..project.id)
                },
                enabled = project.enabled or "null",
                domain_id = project.domain_id or "null",
                name = project.name
            }
        end
    end
    if domain_scoped then
        resp.domains = projects
    else
        resp.projects = projects
    end

    return responses.send_HTTP_OK(resp)
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
            get_scopes(self, dao_factory, false)
        end
    },
    ["/v3/auth/domains"] = {
        GET = function(self, dao_factory)
            get_scopes(self, dao_factory, true)
        end
    }
}