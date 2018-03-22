local responses = require "kong.tools.responses"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")
local utils = require "kong.tools.utils"
local cjson = require "cjson"

local function check_assignment(dao_factory, user_id, project_id, role_id)
    local assignment, err = dao_factory.assignment:find_all({actor_id = user_id, target_id = project_id, role_id = role_id})
    kutils.assert_dao_error(err, "assignment:find_all")

    if not next(assignment) then
        return false
    end

    return true
end

local function create_trust(self, dao_factory)
    if not self.params.trust then
        responses.send_HTTP_BAD_REQUEST("Bad trust object")
    end

    if not self.params.trust.trustee_user_id or not self.params.trust.trustor_user_id then
        responses.send_HTTP_BAD_REQUEST("Bad obligatory params")
    end

    local tmp, err = dao_factory.user:find({id = self.params.trust.trustee_user_id})
    kutils.assert_dao_error(err, "user:find")
    if not tmp then
        responses.send_HTTP_BAD_REQUEST("No such trustee_user_id in the system")
    end

    local tmp, err = dao_factory.user:find({id = self.params.trust.trustor_user_id})
    kutils.assert_dao_error(err, "user:find")
    if not tmp then
        responses.send_HTTP_BAD_REQUEST("No such trustor_user_id in the system")
    end

    local tmp, err = dao_factory.user:find({id = self.params.trust.trustor_user_id})


    if not tmp then
        responses.send_HTTP_BAD_REQUEST("No such trustor_user_id in the system")
    end

    local old_redelegation_count
    if self.params.trust.redelegated_trust_id then
        local redelegated_trust, err = dao_factory.trust:find({id = self.params.redelegated_trust_id})
        kutils.assert_dao_error(err, "trust:find")
        if not tmp then
            responses.send_HTTP_BAD_REQUEST("No such redelegated_trust_id in the system")
        end
        old_redelegation_count = redelegated_trust.redelegation_count
    end

    local trust_obj = self.params.trust
    trust_obj.id = utils.uuid()
    trust_obj.allow_redelegation = trust_obj.allow_redelegation or false
    if not trust_obj.allow_redelegation then
        trust_obj.redelegaion_count = 0
        trust_obj.remaining_uses = nil
    else
        if old_redelegation_count and old_redelegation_count > 0 then
            trust_obj.redelegation_count = old_redelegation_count - 1
        elseif old_redelegation_count == 0 then
            responses.send_HTTP_BAD_REQUEST("Redelegation of this trust is forbidden")
        else
            local max_redelegation_count = kutils.config_from_dao()['max_redelegation_count']
            trust_obj.redelegation_count = trust_obj.redelegation_count or max_redelegation_count
            if trust_obj.redelegation_count > max_redelegation_count then
                trust_obj.redelegation_count = max_redelegation_count
            elseif trust_obj.redelegation_count < 0 then
                responses.send_HTTP_BAD_REQUEST("Bad redelegation count")
            end
        end
    end

    if trust_obj.expires_at then
        trust_obj.expires_at = kutils.string_to_time(trust_obj.expires_at)
    end

    trust_obj.impersonation = trust_obj.impersonation or false

    local trust_roles = {}
    local roles = {}
    for i = 1, #trust_obj.roles do
        local trust_role = {}
        trust_role.trust_id = trust_obj.id
        local role, err
        if trust_obj.roles[i].name then
            role, err = dao_factory.role:find_all({name = trust_obj.roles[i].name})
            kutils.assert_dao_error(err, "role:find_all")
            if not next(role) then
                responses.send_HTTP_BAD_REQUEST("No such role in the system")
            end
            role = role[1]
        elseif trust_obj.roles[i].id then
            role, err = dao_factory.role:find({id = trust_obj.roles[i].id})
            kutils.assert_dao_error(err, "role:find_all")
            if not role then
                responses.send_HTTP_BAD_REQUEST("No such role in the system")
            end
        end
        if check_assignment(dao_factory, trust_obj.trustor_user_id, trust_obj.project_id, role.id) then
            roles[i] = role[1]
            trust_role.role_id = role[1].id
            trust_roles[i] = trust_role
            roles[i].links = {
                    self = self:build_url(self.req.parsed_url.path)
            }
            roles[i].domain_id = nil
        end
    end

    trust_obj.roles = nil

    local _, err = dao_factory.trust:insert(trust_obj)
    kutils.assert_dao_error(err, "trust:insert")
    for i = 1, #trust_roles do
        local _, err = dao_factory.trust_role:insert(trust_roles[i])
        kutils.assert_dao_error(err, "trust_role:insert")
        local _, err = dao_factory.assignment:insert({type = "UserProject", actor_id = trust_obj.trustee_user_id,
                                target_id = trust_obj.project_id, role_id = trust_roles[i].role_id, inherited = false})
        kutils.assert_dao_error(err, "assignment:insert")
    end

    trust_obj.roles = roles
    trust_obj.links = {
                self = self:build_url(self.req.parsed_url.path)
    }
    trust_obj.roles_links = {
        next = nil,
        previous = nil,
        self = self:build_url(self.req.parsed_url.path)
    }

    return 201, {trust = trust_obj}
end

local function list_trusts(self, dao_factory)
    local resp = {
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
            },
            trusts = {}
    }

    local args = {}
    if self.params.trustor_user_id then
        args.trustor_user_id = self.params.trustor_user_id
    end

    if self.params.trustee_user_id then
        args.trustee_user_id = self.params.trustee_user_id
    end

    local trusts = {}
    local err

    if next(args) then
        trusts, err = dao_factory.trust:find_all(args)
        kutils.assert_dao_error(err, "trust:find_all")
    else
        trusts, err = dao_factory.trust:find_all()
        kutils.assert_dao_error(err, "trust:find_all")
    end

    for i = 1, #trusts do
        resp.trusts[i] = trusts[i]
        local trust_roles, err = dao_factory.trust_role:find_all({trust_id = trusts[i].id})
        kutils.assert_dao_error(err, "trust_role:find_all")
        local roles = {}
        for i = 1, #trust_roles do
            local role, err = dao_factory.role:find({id = trust_roles[i].role_id})
            kutils.assert_dao_error(err, "role:find")
            roles[i] = role
            roles[i].links = {
                    self = self:build_url(self.req.parsed_url.path)
            }
            roles[i].domain_id = nil
        end

        resp.trusts[i].roles = roles
        resp.trusts[i].links = {
                    self = self:build_url(self.req.parsed_url.path)
        }
        resp.trusts[i].roles_links = {
            next = nil,
            previous = nil,
            self = self:build_url(self.req.parsed_url.path)
        }
    end

    return 200, resp
end

local function get_trust(self, dao_factory)
    local trust_id = self.params.trust_id
    if not trust_id then
        responses.send_HTTP_BAD_REQUEST("Bad trust id")
    end

    local trust, err = dao_factory.trust:find({id = trust_id})
    kutils.assert_dao_error(err, "trust:find")

    if not trust then
        responses.send_HTTP_BAD_REQUEST("No such trust object in the system")
    end

    local trust_roles, err = dao_factory.trust_role:find_all({trust_id = trust_id})
    kutils.assert_dao_error(err, "trust_role:find_all")

    local roles = {}
    for i = 1, #trust_roles do
        local role, err = dao_factory.role:find({id = trust_roles[i].role_id})
        kutils.assert_dao_error(err, "role:find")
        roles[i] = role
        roles[i].links = {
                self = self:build_url(self.req.parsed_url.path)
        }
        roles[i].domain_id = nil
    end

    trust.roles = roles
    trust.links = {
                self = self:build_url(self.req.parsed_url.path)
    }
    trust.roles_links = {
        next = nil,
        previous = nil,
        self = self:build_url(self.req.parsed_url.path)
    }

    return 200, {trust = trust}
end

local function delete_trust(self, dao_factory)
    local trust_id = self.params.trust_id
    if not trust_id then
        responses.send_HTTP_BAD_REQUEST("Bad trust id")
    end

    local trust, err = dao_factory.trust:find({id = trust_id})
    kutils.assert_dao_error(err, "trust:find")

    if not trust then
        responses.send_HTTP_BAD_REQUEST("No such trust object in the system")
    end

    local trust_roles, err = dao_factory.trust_role:find_all({trust_id = trust_id})
    kutils.assert_dao_error(err, "trust_role:find_all")

    for i = 1, #trust_roles do
        local _, err = dao_factory.trust_role:delete(trust_roles[i])
        kutils.assert_dao_error(err, "trust_role:delete")
        local _, err = dao_factory.assignment:delete({type = "UserProject", actor_id = trust.trustee_user_id,
                                target_id = trust.project_id, role_id = trust_roles[i].role_id, inherited = false})
        kutils.assert_dao_error(err, "assignment:delete")
    end

    local _, err = dao_factory.trust:delete({id = trust_id})
    kutils.assert_dao_error(err, "trust:delete")

    return 204
end

local function list_delegated_roles(self, dao_factory)
    local trust_id = self.params.trust_id
    if not trust_id then
        responses.send_HTTP_BAD_REQUEST("Bad trust id")
    end

    local trust, err = dao_factory.trust:find({id = trust_id})
    kutils.assert_dao_error(err, "trust:find")

    if not trust then
        responses.send_HTTP_BAD_REQUEST("No such trust object in the system")
    end

    local roles = {}
    local trust_roles, err = dao_factory.trust_role:find_all({trust_id = trust_id})
    kutils.assert_dao_error(err, "trust_role:find_all")

    for i = 1, #trust_roles do
        local role, err = dao_factory.role:find({id = trust_roles[i].role_id})
        kutils.assert_dao_error(err, "role:find")
        roles[i] = role
        roles[i].links = {
                self = self:build_url(self.req.parsed_url.path)
        }
        roles[i].domain_id = nil
    end

    return 200, {roles = roles}
end

local function check_role_delegated(self, dao_factory)
    local trust_id = self.params.trust_id
    local role_id = self.params.role_id

    if not trust_id or not role_id then
        responses.send_HTTP_BAD_REQUEST("Bad trust id or role id")
    end

    local trust, err = dao_factory.trust:find({id = trust_id})
    kutils.assert_dao_error(err, "trust:find")

    if not trust then
        responses.send_HTTP_BAD_REQUEST("No such trust object in the system")
    end

    local role, err = dao_factory.role:find({id = role_id})
    kutils.assert_dao_error(err, "role:find")

    if not role then
        responses.send_HTTP_BAD_REQUEST("No such role object in the system")
    end

    local trust_role, err = dao_factory.trust_role:find({trust_id = trust_id, role_id = role_id})
    kutils.assert_dao_error(err, "trust_role:find")

    if not trust_role then
        responses.send_HTTP_BAD_REQUEST("No such trust role object in the system")
    end

    return 200
end

local function get_delegated_role(self, dao_factory)
    local trust_id = self.params.trust_id
    local role_id = self.params.role_id

    if not trust_id or not role_id then
        responses.send_HTTP_BAD_REQUEST("Bad trust id or role id")
    end

    local trust, err = dao_factory.trust:find({id = trust_id})
    kutils.assert_dao_error(err, "trust:find")

    if not trust then
        responses.send_HTTP_BAD_REQUEST("No such trust object in the system")
    end

    local role, err = dao_factory.role:find({id = role_id})
    kutils.assert_dao_error(err, "role:find")

    if not role then
        responses.send_HTTP_BAD_REQUEST("No such role object in the system")
    end

    local trust_role, err = dao_factory.trust_role:find({trust_id = trust_id, role_id = role_id})
    kutils.assert_dao_error(err, "trust_role:find")

    if not trust_role then
        responses.send_HTTP_BAD_REQUEST("No such trust role object in the system")
    end

    role.links = {
                self = self:build_url(self.req.parsed_url.path)
    }
    role.domain_id = nil

    return 200, {role = role}
end

local routes = {
    ['/v3/OS-TRUST/trusts'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_trusts", dao_factory, self.params)
            responses.send(list_trusts(self, dao_factory))
        end,
        POST = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_trust", dao_factory, self.params)
            responses.send(create_trust(self, dao_factory))
        end
    },
    ['/v3/OS-TRUST/trusts/:trust_id'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_trust", dao_factory, self.params)
            responses.send(get_trust(self, dao_factory))
        end,
        DELETE = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_trust", dao_factory, self.params)
            responses.send(delete_trust(self, dao_factory))
        end
    },
    ['/v3/OS-TRUST/trusts/:trust_id/roles/'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_delegated_roles", dao_factory, self.params)
            responses.send(list_delegated_roles(self, dao_factory))
        end,
    },
    ['/v3/OS-TRUST/trusts/:trust_id/roles/:role_id'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_delegated_role", dao_factory, self.params)
            responses.send(get_delegated_role(self, dao_factory))
        end,
        HEAD = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:check_role_delegated", dao_factory, self.params)
            responses.send(check_role_delegated(self, dao_factory))
        end
    },
}

local function consuming_trust(self, dao_factory)
    local check_token = require ("kong.plugins.keystone.views.auth_and_tokens").check_token
    local roles = require ("kong.plugins.keystone.views.roles")
    local assignment = roles.assignment
    local auth_user = check_token(self.params.auth.identity.token, dao_factory)

    local trust_id = self.params.auth.scope['OS-TRUST:trust'].id
    if not trust_id then
        return responses.send_HTTP_BAD_REQUEST("Trust id must present in the request")
    end

    local trust, err = dao_factory.trust:find({id = trust_id})
    kutils.assert_dao_error(err, "trust:find")

    if not trust then
        return responses.send_HTTP_BAD_REQUEST("No such trust in the system")
    end

    if auth_user.id ~= trust.trustee_user_id then
        return responses.send_HTTP_BAD_REQUEST("auth_user.id ~= trust.trustee_user_id")
    end

    self.params.user_id = auth_user.id
    self.params.project_id = trust.project_id
    local temp = assignment.list(self, dao_factory, "UserProject")
    if not next(temp.roles) then
        return responses.send_HTTP_UNAUTHORIZED("User has no assignments for project/domain") -- code 401
    end

    if trust.impersonation then
        local err
        auth_user, err = dao_factory.user:find({id = trust.trustor_user_id})
        kutils.assert_dao_error(err, "user:find")
    end

    local Tokens = kutils.provider()
    local token = Tokens.generate(dao_factory, auth_user, true, trust.project_id, false, trust_id)

    local domain, err = dao_factory.project:find({id = auth_user.domain_id or auth_user.domain.id})
    kutils.assert_dao_error(err, "project:find")

    local resp = {}
    auth_user.default_project_id = nil
    auth_user.created_at = nil
    auth_user.domain_id = nil
    auth_user.domain = {id = domain.id, name = domain.name, links = {self = self:build_url(self.req.parsed_url.path)}}
    auth_user.links = {
                self = self:build_url(self.req.parsed_url.path)
        }
    resp.user = auth_user

    local cache = Tokens.get_info(token.id, dao_factory)
    resp.expires_at = kutils.time_to_string(token.expires)
    resp.issued_at = kutils.time_to_string(cache.issued_at)
    resp.methods = {"token"}
    trust.trustor_user = {id = trust.trustor_user_id, links = {
                self = self:build_url(self.req.parsed_url.path)
        }}
    trust.trustee_user = {id = trust.trustee_user_id, links = {
                self = self:build_url(self.req.parsed_url.path)
        }}
    trust.trustor_user_id = nil
    trust.trustee_user_id = nil
    resp['OS-TRUST:trust'] = trust

    return responses.send_HTTP_CREATED({token = resp}, {["X-Subject-Token"] = token.id})
end

return { routes = routes, auth = consuming_trust }