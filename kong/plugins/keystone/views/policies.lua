local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")
local cjson = require 'cjson'

local Policy = {}

local function list_policies(self, dao_factory)
    local resp = {
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
        },
        policies = {}
    }

    local policies = {}
    local err
    if self.params.type then
        policies, err = dao_factory.policy:find_all({type=self.params.type})
    else
        policies, err = dao_factory.policy:find_all()
    end
    kutils.assert_dao_error(err, "policy:find_all")

    if not next(policies) then
        return responses.send_HTTP_OK(resp)
    end

    for i = 1, kutils.list_limit(#policies, self.config) do
        resp.policies[i] = policies[i]
        resp.policies[i].links = {
                self = self:build_url(self.req.parsed_url.path)
        }
    end

    return responses.send_HTTP_OK(resp)
end

local function create_policy(self, dao_factory)
    if not self.params.policy then
        return responses.send_HTTP_BAD_REQUEST("Policy is nil, check self.params")
    end

    local policy_obj = {}
    policy_obj.type = self.params.policy.type
    policy_obj.blob = self.params.policy.blob
    policy_obj.id = utils.uuid()

    local policy, err = dao_factory.policy:insert(policy_obj)
    kutils.assert_dao_error(err, "policy insert")
    if not policy then
            return responses.send_HTTP_CONFLICT({error = err, object = policy_obj})
    end

    policy.links = {
                self = self:build_url(self.req.parsed_url.path)
    }

    return responses.send_HTTP_CREATED({policy = policy})
end

local function get_policy_info(self, dao_factory)
    local policy_id = self.params.policy_id
    if not policy_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy id")
    end

    local policy, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")

    if not policy then
        return responses.send_HTTP_BAD_REQUEST("No such policy in the system")
    end

    policy.links = {
                self = self:build_url(self.req.parsed_url.path)
    }

    return responses.send_HTTP_OK({policy = policy})
end

local function update_policy(self, dao_factory)
    local policy_id = self.params.policy_id
    if not policy_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy id")
    end

    local policy, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")

    if not self.params.policy then
         return responses.send_HTTP_BAD_REQUEST("Policy is nil, check self.params")
    end

    local params = {}
    if self.params.policy.type then
        params.type = self.params.type
    end

    if self.params.policy.blob then
        params.blob = blob
    end

    local updated_policy, err = dao_factory.policy:update(self.params.policy, {id=policy.id})
    kutils.assert_dao_error(err, "policy update")

    updated_policy.links = {
                self = self:build_url(self.req.parsed_url.path)
    }

    return responses.send_HTTP_OK({policy = updated_policy})
end

local function delete_policy(self, dao_factory)
   local policy_id = self.params.policy_id
    if not policy_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy id")
    end

    local policy, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")

    local _, err = dao_factory.policy:delete({id = policy_id})
    kutils.assert_dao_error(err, "policy delete")

    return responses.send_HTTP_NO_CONTENT()
end

Policy.list_policies = list_policies
Policy.create_policy = create_policy
Policy.get_policy_info = get_policy_info
Policy.update_policy = update_policy
Policy.delete_policy = delete_policy

return {
    ["/v3/policies"] = {
        GET = function(self, dao_factory)
            policies.check(self, dao_factory, "identity:list_policies")
            Policy.list_policies(self, dao_factory)
        end,
        POST = function(self, dao_factory)
            policies.check(self, dao_factory, "identity:create_policy")
            Policy.create_policy(self, dao_factory)
        end
    },
    ["/v3/policies/:policy_id"] = {
        GET = function(self, dao_factory)
            policies.check(self, dao_factory, "identity:get_policy")
            Policy.get_policy_info(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            policies.check(self, dao_factory, "identity:update_policy")
            Policy.update_policy(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            policies.check(self, dao_factory, "identity:delete_policy")
            Policy.delete_policy(self, dao_factory)
        end
    }
}