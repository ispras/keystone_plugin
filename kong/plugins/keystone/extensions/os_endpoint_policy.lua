local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")
local cjson = require 'cjson'

local function verify_policy_endpoint_association(self, dao_factory)
    local policy_id = self.params.policy_id
    local endpoint_id = self.params.endpoint_id
    if not endpoint_id or not policy_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy or endpoint id")
    end

    local _, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")
    local _, err = dao_factory.endpoint:find({id=endpoint_id})
    kutils.assert_dao_error(err, "endpoint find")

    local policy_association, err = dao_factory.policy_association:find_all({policy_id = policy_id, endpoint_id = endpoint_id})
    kutils.assert_dao_error(err, "policy association find all")
    if not next(policy_association) then
        return responses.send_HTTP_BAD_REQUEST("Error: no such association")
    end
    return responses.send_HTTP_NO_CONTENT()
end

local function associate_policy_endpoint(self, dao_factory)
    local policy_id = self.params.policy_id
    local endpoint_id = self.params.endpoint_id
    if not endpoint_id or not policy_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy or endpoint id")
    end

    local _, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")
    local endpoint, err = dao_factory.endpoint:find({id=endpoint_id})
    kutils.assert_dao_error(err, "endpoint find")

    local policy_assoiation_id = utils.uuid()
    local policy_association = {id = policy_assoiation_id, policy_id = policy_id, endpoint_id = endpoint_id}

    local _, err = dao_factory.policy_association:insert(policy_association)
    kutils.assert_dao_error(err, "policy association insert")
    return responses.send_HTTP_NO_CONTENT()
end

local function delete_policy_endpoint_association(self, dao_factory)
    local policy_id = self.params.policy_id
    local endpoint_id = self.params.endpoint_id
    if not endpoint_id or not policy_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy or endpoint id")
    end

    local _, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")
    local _, err = dao_factory.endpoint:find({id=endpoint_id})
    kutils.assert_dao_error(err, "endpoint find")

    local policy_association, err = dao_factory.policy_association:find_all({policy_id = policy_id, endpoint_id = endpoint_id})
    kutils.assert_dao_error(err, "policy association find all")
    if not next(policy_association) then
        return responses.send_HTTP_BAD_REQUEST("Error: no such association")
    end

    local _, err = dao_factory.policy_association:delete({id=policy_association[1].id})
    kutils.assert_dao_error(err, "policy association delete")
    return responses.send_HTTP_NO_CONTENT()
end

local function verify_policy_service_association(self, dao_factory)
    local policy_id = self.params.policy_id
    local service_id = self.params.service_id
    if not service_id or not policy_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy or service id")
    end

    local _, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")
    local _, err = dao_factory.service:find({id=service_id})
    kutils.assert_dao_error(err, "service find")

    local policy_association, err = dao_factory.policy_association:find_all({policy_id = policy_id, service_id = service_id})
    kutils.assert_dao_error(err, "policy association find all")
    if not next(policy_association) then
        return responses.send_HTTP_BAD_REQUEST("Error: no such association")
    end
    return responses.send_HTTP_NO_CONTENT()
end

local function associate_policy_service(self, dao_factory)
    local policy_id = self.params.policy_id
    local service_id = self.params.service_id
    if not service_id or not policy_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy or service id")
    end

    local _, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")
    local _, err = dao_factory.service:find({id=service_id})
    kutils.assert_dao_error(err, "service find")

    local endpoint, err = dao_factory.endpoint:find_all({service_id=service_id})
    kutils.assert_dao_error(err, "endpoint find all")
    if not next(endpoint) then
        return responses.send_HTTP_BAD_REQUEST("Error: no such endpoints for this service")
    end

    endpoint = endpoint[1]
    local policy_assoiation_id = utils.uuid()
    local policy_association = {id = policy_assoiation_id, policy_id = policy_id, service_id = service_id,
                                endpoint_id = endpoint.id}

    local _, err = dao_factory.policy_association:insert(policy_association)
    kutils.assert_dao_error(err, "policy association insert")
    return responses.send_HTTP_NO_CONTENT()
end

local function delete_policy_service_association(self, dao_factory)
    local policy_id = self.params.policy_id
    local service_id = self.params.service_id
    if not service_id or not policy_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy or service id")
    end

    local _, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")
    local _, err = dao_factory.service:find({id=service_id})
    kutils.assert_dao_error(err, "service find")

    local policy_association, err = dao_factory.policy_association:find_all({policy_id = policy_id, service_id = service_id})
    kutils.assert_dao_error(err, "policy association find all")
    if not next(policy_association) then
        return responses.send_HTTP_BAD_REQUEST("Error: no such association")
    end

    local _, err = dao_factory.policy_association:delete({id=policy_association[1].id})
    kutils.assert_dao_error(err, "policy association delete")
    return responses.send_HTTP_NO_CONTENT()
end

local function show_policy(self, dao_factory)
    local policy_id = self.params.policy_id
    if not policy_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy id")
    end

    local policy, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")

    local policy_association, err = dao_factory.policy_association:find_all({policy_id = policy_id})
    kutils.assert_dao_error(err, "policy association find all")
    if not next(policy_association) then
        return responses.send_HTTP_BAD_REQUEST("Error: no such associations")
    end

    policy.extra = nil
    policy.links = {
                self = self:build_url(self.req.parsed_url.path)
    }
    return responses.send_HTTP_OK({policy = policy})
end

local function check_policy(self, dao_factory)
    local policy_id = self.params.policy_id
    if not policy_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy id")
    end

    local policy, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")

    local policy_association, err = dao_factory.policy_association:find_all({policy_id = policy_id})
    kutils.assert_dao_error(err, "policy association find all")
    if not next(policy_association) then
        return responses.send_HTTP_BAD_REQUEST("Error: no such associations")
    end

    return responses.send_HTTP_OK()
end

local function verify_policy_in_region(self, dao_factory)
    local policy_id = self.params.policy_id
    local service_id = self.params.service_id
    local region_id = self.params.region_id
    if not service_id or not policy_id or not region_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy or service or region id")
    end

    local _, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")
    local _, err = dao_factory.service:find({id=service_id})
    kutils.assert_dao_error(err, "service find")
    local _, err = dao_factory.region:find({id=region_id})
    kutils.assert_dao_error(err, "region find")

    local policy_association, err = dao_factory.policy_association:find_all({policy_id = policy_id, service_id = service_id,
                                                                            region_id = region_id})
    kutils.assert_dao_error(err, "policy association find all")
    if not next(policy_association) then
        return responses.send_HTTP_BAD_REQUEST("Error: no such association")
    end
    return responses.send_HTTP_NO_CONTENT()
end

local function associate_policy_in_region(self, dao_factory)
    local policy_id = self.params.policy_id
    local service_id = self.params.service_id
    local region_id = self.params.region_id
    if not service_id or not policy_id or not region_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy or service or region id")
    end

    local _, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")
    local _, err = dao_factory.service:find({id=service_id})
    kutils.assert_dao_error(err, "service find")
    local _, err = dao_factory.region:find({id=region_id})
    kutils.assert_dao_error(err, "region find")

    local endpoint, err = dao_factory.endpoint:find_all({service_id=service_id, region_id = region_id})
    kutils.assert_dao_error(err, "endpoint find all")
    if not next(endpoint) then
        return responses.send_HTTP_BAD_REQUEST("Error: no such endpoints for this service")
    end

    endpoint = endpoint[1]
    local policy_assoiation_id = utils.uuid()
    local policy_association = {id = policy_assoiation_id, policy_id = policy_id, service_id = service_id,
                                endpoint_id = endpoint.id, region_id = region_id }

    local _, err = dao_factory.policy_association:insert(policy_association)
    kutils.assert_dao_error(err, "policy association insert")

    return responses.send_HTTP_NO_CONTENT()
end

local function delete_policy_in_region_association(self, dao_factory)
    local policy_id = self.params.policy_id
    local service_id = self.params.service_id
    local region_id = self.params.region_id
    if not service_id or not policy_id or not region_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy or service or region id")
    end

    local _, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")
    local _, err = dao_factory.service:find({id=service_id})
    kutils.assert_dao_error(err, "service find")
    local _, err = dao_factory.region:find({id=region_id})
    kutils.assert_dao_error(err, "region find")

    local policy_association, err = dao_factory.policy_association:find_all({policy_id = policy_id,
                                                                            service_id = service_id, region_id = region_id})
    kutils.assert_dao_error(err, "policy association find all")
    if not next(policy_association) then
        return responses.send_HTTP_BAD_REQUEST("Error: no such association")
    end

    local _, err = dao_factory.policy_association:delete({id=policy_association[1].id})
    kutils.assert_dao_error(err, "policy association delete")
    return responses.send_HTTP_NO_CONTENT()
end

local function list_endpoints_for_policy(self, dao_factory)
    local policy_id = self.params.policy_id
    if not policy_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad policy id")
    end

    local _, err = dao_factory.policy:find({id=policy_id})
    kutils.assert_dao_error(err, "policy find")

    local policy_association, err = dao_factory.policy_association:find_all({policy_id = policy_id,
                                                                            service_id = service_id, region_id = region_id})
    kutils.assert_dao_error(err, "policy association find all")
    if not next(policy_association) then
        return responses.send_HTTP_OK({})
    end

    local resp = {
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
            },
            endpoints = {}
    }

    local idx = 1
    for i = 1, #policy_association do
        if policy_association[i].endpoint_id then
            local endpoint, err = dao_factory.endpoint:find({id = policy_association[i].endpoint_id})
            kutils.assert_dao_error(err, "endpoint find")
            endpoint.legacy_endpoint_id = nil
            endpoint.links = {self = self:build_url(self.req.parsed_url.path) }
            endpoint.extra = nil
            endpoint.enabled = nil
            resp.endpoints[idx] = endpoint
            idx = idx + 1
        end
    end

    return responses.send_HTTP_OK(resp)
end

local function get_policy_for_endpoint(self, dao_factory)
    local endpoint_id = self.params.endpoint_id
    if not endpoint_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad endpoint id")
    end

    local _, err = dao_factory.endpoint:find({id=endpoint_id})
    kutils.assert_dao_error(err, "endpoint find")

    local policy_association, err = dao_factory.policy_association:find_all({endpoint_id = endpoint_id})
    kutils.assert_dao_error(err, "policy association find all")
    if not next(policy_association) then
        return responses.send_HTTP_BAD_REQUEST("Error: no such associations")
    end

    local policy, err = dao_factory.policy:find({id=policy_association[1].policy_id})
    kutils.assert_dao_error(err, "endpoint find")
    policy.extra = nil
    policy.links = {
                self = self:build_url(self.req.parsed_url.path)
    }
    return responses.send_HTTP_OK({policy = policy})
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
        HEAD = function(self, dao_factory)
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
    ["/v3/policies/:policy_id/OS-ENDPOINT-POLICY/services/:service_id"] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:check_policy_association_for_service", dao_factory, self.params)
            OsEndpointPolicy.verify_policy_service_association(self, dao_factory)
        end,
        HEAD = function(self, dao_factory)
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
            policies.check(self.req.headers['X-Auth-Token'], "identity:show policy for endpoint", dao_factory, self.params)
            OsEndpointPolicy.show_policy(self, dao_factory)
        end,
        HEAD = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:check_policy_and_service_endpoint_association", dao_factory, self.params)
            OsEndpointPolicy.check_policy(self, dao_factory)
        end
    },
    ["/v3/policies/:policy_id/OS-ENDPOINT-POLICY/services/:service_id/regions/:region_id"] = {
        HEAD = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:check_policy_association_for_region_and_service", dao_factory, self.params)
            OsEndpointPolicy.verify_policy_in_region(self, dao_factory)
        end,
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
    },
    ["/v3/endpoints/:endpoint_id/OS-ENDPOINT-POLICY/policy"] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_policy_for_endpoint", dao_factory, self.params)
            OsEndpointPolicy.get_policy_for_endpoint(self, dao_factory)
        end
    }
}