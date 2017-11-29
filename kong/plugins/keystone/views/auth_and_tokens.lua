local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local sha512 = require('sha512')
local kutils = require ("kong.plugins.keystone.utils")
local roles = require ("kong.plugins.keystone.views.roles")
local assignment = roles.assignment
local services_and_endpoints = require("kong.plugins.keystone.views.services_and_endpoints")
local service = services_and_endpoints.services
local endpoint = services_and_endpoints.endpoints

--TODO A token without an explicit scope of authorization is issued if the user does not specify a project and does not have authorization on the project specified by their default project attribute

local function check_user(user, dao_factory)
    local loc_user, domain
    if not (user.id or user.name and (user.domain.name or user.domain.id)) then
        return {message = "User info is required"}
    else
        if user.id then
            local err
            user, err = dao_factory.user:find({id = user.id})
            kutils.assert_dao_error(err, "user find")
            local temp, err = dao_factory.local_user:find_all({user_id = user.id})
            kutils.assert_dao_error(err, "local_user find_all")
            if not next(temp) then
                return {message = "Requested user is not local"}
            end
            loc_user = temp[1]
        else
            if not user.domain.id then
                local temp, err = dao_factory.project:find_all({is_domain = true, name = user.domain.name})
                kutils.assert_dao_error(err, "project find_all")
                if not next(temp) then
                    return {message = "Requested domain is not found, check domain name = "..user.domain.name}
                end
                domain = temp[1]
                user.domain.id = domain.id
            end

--            local temp, err = dao_factory.local_user:find_all ({name = user.name, domain_id = user.domain.id})
            local temp, err = dao_factory.local_user:find_all ({name = user.name})
            kutils.assert_dao_error(err, "local_user find_all")

            if not next(temp) then
                return {message = "Requested user is not found, check user name = "..user.name .. " with domain id = " .. user.domain.id}
            end
            loc_user = temp[1]
            user, err = dao_factory.user:find({id = loc_user.user_id})
            kutils.assert_dao_error(err, "user find")
        end
    end

    if not domain then
        local err
        domain, err = dao_factory.project:find({id = user.domain_id})
        kutils.assert_dao_error(err, "project:find")
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
    kutils.assert_dao_error(err, "password:find_all")
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
            kutils.assert_dao_error(err, "project:find")
            if not temp then
                return {message = "No requsted project for scope found" }
            end
            project = temp
            local temp, err = dao_factory.project:find({id = project.domain_id})
            kutils.assert_dao_error(err, "project:find")
            domain_name = temp[1].name
        elseif scope.project.name and scope.project.domain and (scope.project.domain.id or scope.project.domain.name) then
            if not scope.project.domain.id then
                local temp, err = dao_factory.project:find_all ({name = scope.project.domain.name, is_domain = true})
                kutils.assert_dao_error(err, "project:find_all")
                if not next(temp) then
                    return {message = "No domain whith specified name = "..scope.project.domain.name }
                end
                scope.project.domain.id = temp[1].id
            else
                local temp, err = dao_factory.project:find ({id = scope.project.domain.id})
                kutils.assert_dao_error(err, "project:find")
            end
            domain_name = scope.project.domain.name

--            local temp, err = dao_factory.project:find_all({name = scope.project.name, domain_id = scope.project.domain.id})
            local temp, err = dao_factory.project:find_all({name = scope.project.name})
            kutils.assert_dao_error(err, "project:find_all")
            if not next(temp) then
                return {message = "No requested project found for scope, domain id is: " ..  scope.project.domain.id .. " and project name is " .. scope.project.name}
            end
            project = temp[1]
            local temp, err = dao_factory.assignment:find_all({type = ""})
        else
            return {message = "Project needs to be identified unique" }
        end

    elseif scope.domain then
        if scope.domain.id then
            local temp, err = dao_factory.project:find({id = scope.domain.id})
            kutils.assert_dao_error(err, "project:find")
            project = temp

        elseif scope.domain.name then
            local temp, err = dao_factory.project:find_all({name = scope.domain.name, is_domain = true})
            kutils.assert_dao_error(err, "project:find_all")
            if not next(temp) then
                return {message = "No domain found with requested name" }
            end
            project = temp[1]
        else
            return {message = "Domain needs to be identified unique" }
        end

        if project.domain_id then
            local temp, err = dao_factory.project:find({id = project.domain_id})
            kutils.assert_dao_error(err, "project:find")
            domain_name = temp.name
        end

    else
        return {message = "No domain or project requested for scope"}
    end

    return nil, project, domain_name
end

local function get_catalog(self,dao_factory)
    local temp = service.list(self,dao_factory, true)
    local catalog = temp.services
    for i = 1, #catalog do
        catalog[i].description = nil
        catalog[i].links = nil
        catalog[i].enabled = nil
        self.params.service_id = catalog[i].id
        local temp = endpoint.list(self, dao_factory, true)
        catalog[i].endpoints = temp.endpoints
        for j = 1, #catalog[i].endpoints do
            catalog[i].endpoints[j].enabled = nil
            catalog[i].endpoints[j].service_id = nil
            catalog[i].endpoints[j].links = nil
        end
    end

    return nil, catalog
end

local function check_token_auth(token, dao_factory, allow_expired, validate)
    local err
    if not token or not token.id then
        err = {message = "Token id is required"}
    end

    local temp, err = dao_factory.token:find({id = token.id})
    kutils.assert_dao_error(err, "token:find")
    if not temp then
        err = {message = "No token found" }
        return token, err
    end
    token = temp
    if not validate then
        if token.valid == false then
            err = {message = "Token is not valid" }
            return token, err
        end
    elseif not token.valid then
        token, err = dao_factory.token:update({valid = true}, {id = token.id})
        kutils.assert_dao_error(err, "token:update")
    end
    if not allow_expired then
        if token.expires and token.expires < os.time() then
            err =  {message = "Token is expired" }
            return token, err
        end
    end
    return token, err
end

local function check_token_user (token, dao_factory, allow_expired, validate)
    local token, err = check_token_auth(token, dao_factory, allow_expired, validate)
    if err then
        return err
    end

    if not token.user_id then
        return responses.send_HTTP_NOT_FOUND("Error: token.user_id is nil")
    end
    local user, err = dao_factory.user:find({id = token.user_id})
    kutils.assert_dao_error(err, "user:find")
    local domain, err = dao_factory.project:find({id = user.domain_id})
    kutils.assert_dao_error(err, "project:find")
    local loc_user, err = dao_factory.local_user:find_all({user_id = user.id})
    kutils.assert_dao_error(err, "local_user:find_all")
    local password, err = dao_factory.password:find_all({local_user_id = loc_user[1].id})
    kutils.assert_dao_error(err, "password:find_all")

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
    kutils.assert_dao_error(err, "token:insert")
    local token, err = dao_factory.token:find({id = token.id})
    kutils.assert_dao_error(err, "token:find")

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

    self.params.actor_id = user.id
    self.params.target_id = project.domain_id

    local temp = assignment.list(self, dao_factory, "UserDomain") --scope.project and "UserProject" or
    if not next(temp.roles) then
        return responses.send_HTTP_UNAUTHORIZED("User has no assignments for project/domain") -- code 401
    end
    local roles = temp.roles

    local token = {
        id = utils.uuid(),
        valid = true,
        user_id = user.id,
        expires = os.time() + 24*60*60
    }
    local token, err = dao_factory.token:insert(token)
    kutils.assert_dao_error(err, "token:insert")

    resp = {
        token = {
            methods = {"password"},
            roles = roles,
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
            issued_at = kutils.time_to_string(os.time()),
            expires_at = kutils.time_to_string(os.time() + 60 * 60) --TODO: fix it
        }
    }
    if not (self.params.nocatalog) then
        local err, catalog = get_catalog(self, dao_factory)
        kutils.assert_dao_error(err, "get_catalog")
        resp.token.catalog = catalog or {}
    end

    local cache = {
        token_id = token.id,
        scope_id = project.id,
        roles = kutils.roles_to_string(roles)
    }
    local _,err = dao_factory.cache:insert(cache)
    kutils.assert_dao_error(err)

--TODO cache
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
    kutils.assert_dao_error(err, "token:insert")

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
    --TODO:
    --self.params.actor_id =
    --self.params.target_id =
    local temp = assignment.list(self, dao_factory, scope.project and "UserProject" or "UserDomain")
    if not next(temp.roles) then
        return responses.send_HTTP_UNAUTHORIZED("User has no assignments for project/domain") -- code 401
    end
    local roles = temp.roles

    local token = {
        id = utils.uuid(),
        valid = true,
        user_id = user.id,
        expires = os.time() + 24*60*60
    }
    local token, err = dao_factory.token:insert(token)
    kutils.assert_dao_error(err, "token:insert")

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
        local err, catalog = get_catalog(self, dao_factory)
        kutils.assert_dao_error(err, "get_catalog")
        resp.token.catalog = catalog or {}
    end
    local cache = {
        token_id = token.id,
        scope_id = project.id,
        roles = kutils.roles_to_string(roles)
    }
    local _,err = dao_factory.cache:insert(cache)
    kutils.assert_dao_error(err)
    
-- TODO cache
    return responses.send_HTTP_CREATED(resp, {["X-Subject-Token"] = token.id})
end

local function get_token_info(self, dao_factory)
    local auth_token = self.req.headers["X-Auth-Token"]
    local subj_token = self.req.headers["X-Subject-Token"]

    local token = {
        id = auth_token
    }
    local token, err = check_token_auth(token, dao_factory)
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
    kutils.assert_dao_error(err, "assignments:find_all")
    for i = 1, #temp do
        local role, err = dao_factory.role:find({id = temp[i].role_id})
        kutils.assert_dao_error(err, "role:find")
        if not role then
            resp.token.roles[i] = {
                id = role.id,
                name = role.name
            }
        end

    end

    if not (self.params.nocatalog) then
        local err, catalog = get_catalog(self,dao_factory)
        kutils.assert_dao_error(err, "get_catalog")
        resp.token.catalog = catalog or {}
    end

    return responses.send_HTTP_OK(resp, {["X-Subject-Token"] = token.id})
end

local function check_token(self, dao_factory)
    local auth_token = self.req.headers["X-Auth-Token"]
    local subj_token = self.req.headers["X-Subject-Token"]

    local token = {
        id = auth_token
    }
    local token, err = check_token_auth(token, dao_factory)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end
    token = {
        id = subj_token
    }
    local token, err = check_token_auth(token, dao_factory, self.params.allow_expired, true)
    if err then
        return responses.send_HTTP_BAD_REQUEST(err)
    end

    -- TODO Identity API?

    return responses.send_HTTP_OK()
end

local function revoke_token(self, dao_factory)
    -- TODO revocation event?
    local subj_token = self.req.headers["X-Subject-Token"]
    if not subj_token then
        return responses.send_HTTP_BAD_REQUEST({message = "Specify header X-Subject-Token for token id"})
    end

    local token = {
        id = subj_token
    }
    local _, err = dao_factory.token:update({valid = false}, {id = token.id})
    kutils.assert_dao_error(err, "token update")

    return responses.send_HTTP_NO_CONTENT()
end

local function get_service_catalog(self, dao_factory)
    local auth_token = self.req.headers["X-Auth-Token"]
    local token = {
        id = auth_token
    }
    local token, err = check_token_auth(token, dao_factory)
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

    local err, catalog = get_catalog(self,dao_factory)
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
    kutils.assert_dao_error(err, "assignment:find_all")
    for i = 1, #temp do
        local project, err = dao_factory.project:find({id = temp[i].target_id})
        kutils.assert_dao_error(err, "project:find")
        if project then
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

local routes =  {
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

routes["/v2.0/auth/tokens"] = routes["/v3/auth/tokens"]

return routes