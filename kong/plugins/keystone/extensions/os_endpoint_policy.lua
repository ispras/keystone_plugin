local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")

local function verify_policy_endpoint_association(self, dao_factory)
    local policy_id = self.params.policy_id
    local endpoint_id = self.params.endpoint_id
    if not endpoint_id or not policy_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy or endpoint id")
    end

    local _, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")
    local endpoint, err = dao_factory.policy:find({id=endpoint_id})
    kutils.assert_dao_error(err, "endpoint find")

end

local OsEndpointPolicy = {}

OsEndpointPolicy.verify_policy_endpoint_association = verify_policy_endpoint_association
OsEndpointPolicy.associate_policy_endpoint = associate_policy_endpoint
OsEndpointPolicy.delete_policy_endpoint_association = delete_policy_endpoint_association
OsEndpointPolicy.verify_policy_service_association = verify_policy_service_association
OsEndpointPolicy.associate_policy_service = associate_policy_service
OsEndpointPolicy.delete_policy_service_association = delete_policy_service_association
OsEndpointPolicy.show_policy = show_policy
OsEndpointPolicy.check_policy = check_policy
OsEndpointPolicy.verify_policy_in_region = verify_policy_in_region
OsEndpointPolicy.associate_policy_in_region = associate_policy_in_region
OsEndpointPolicy.delete_policy_in_region_association = delete_policy_in_region_association
OsEndpointPolicy.list_endpoints_for_policy = list_endpoints_for_policy
OsEndpointPolicy.get_policy_for_endpoint = get_policy_for_endpoint

return {
    ["/v3/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:endpoint_id"] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:check_policy_association_for_endpoint", dao_factory, self.params)
            OsEndpointPolicy.verify_policy_endpoint_association(self, dao_factory)
        end,
        PUT = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_policy_association_for_endpoint", dao_factory, self.params)
            OsEndpointPolicy.associate_policy_endpoint(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_policy_association_for_endpoint", dao_factory, self.params)
            OsEndpointPolicy.delete_policy_endpoint_association(self, dao_factory)
        end
    },
    ["/v3/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints/:service_id"] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:check_policy_association_for_service", dao_factory, self.params)
            OsEndpointPolicy.verify_policy_service_association(self, dao_factory)
        end,
        PUT = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_policy_association_for_service", dao_factory, self.params)
            OsEndpointPolicy.associate_policy_service(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_policy_association_for_service", dao_factory, self.params)
            OsEndpointPolicy.delete_policy_service_association(self, dao_factory)
        end
    },
    ["/v3/policies/:policy_id/OS-ENDPOINT-POLICY/policy"] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_policy_for_endpoint", dao_factory, self.params)
            OsEndpointPolicy.show_policy(self, dao_factory)
        end,
        HEAD = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:check_policy_association_for_endpoint", dao_factory, self.params)
            OsEndpointPolicy.check_policy(self, dao_factory)
        end
    },
    ["/v3/policies/:policy_id/OS-ENDPOINT-POLICY/services/:service_id/regions/:region_id"] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:check_policy_association_for_region_and_service", dao_factory, self.params)
            OsEndpointPolicy.verify_policy_in_region(self, dao_factory)
        end,
        PUT = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_policy_association_for_region_and_service", dao_factory, self.params)
            OsEndpointPolicy.associate_policy_in_region(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_policy_association_for_region_and_service", dao_factory, self.params)
            OsEndpointPolicy.delete_policy_in_region_association(self, dao_factory)
        end
    },
    ["/v3/policies/:policy_id/OS-ENDPOINT-POLICY/endpoints"] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_endpoints_for_policy", dao_factory, self.params)
            OsEndpointPolicy.list_endpoints_for_policy(self, dao_factory)
        end
    }
    ,
    ["/v3/endpoints/:endpoint_id/OS-ENDPOINT-POLICY/policy"] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_policy_for_endpoint", dao_factory, self.params)
            OsEndpointPolicy.get_policy_for_endpoint(self, dao_factory)
        end
    }
}