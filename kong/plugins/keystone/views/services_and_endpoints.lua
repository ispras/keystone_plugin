local responses = require "kong.tools.responses"
local crud = require "kong.api.crud_helpers"
local cjson = require "cjson"
local utils = require "kong.tools.utils"
local kstn_utils = require ("kong.plugins.keystone.utils")

ServiceAndEndpoint = {}

local available_service_types = {
    compute = true, ec2 = true, identity = true, image = true, network = true, volume = true
}

function list_services(self, dao_factory)
    local resp = {
        links = {
            next = "null",
            previous = "null",
            self = self:build_url(self.req.parsed_url.path)
        },
        services = {}
    }

    local services = {}
    local err
    if self.params.type then
        services, err = dao_factory.service:find_all({type = self.params.type})
    else
        services, err = dao_factory.service:find_all()
    end

    if err then
        return responses.send_HTTP_BAD_REQUEST({error = err, func = "dao_factory.region:find_all(...)"})
    end

    if not next(regions) then
        return responses.send_HTTP_OK(resp)
    end

    for i = 1, #regions do
        resp.services[i] = {}
        resp.services[i].description = services[i].description
        resp.services[i].id = services[i].id
        resp.services[i].links = {
                self = self:build_url(self.req.parsed_url.path)
        }
        resp.services[i].enabled = services[i].enabled
        resp.services[i].name = services[i].name
        resp.services[i].type = services[i].type
    end
    return responses.send_HTTP_OK(resp)
end

function create_service(self, dao_factory)
    local service = self.params.service
    if not service then
        return responses.send_HTTP_BAD_REQUEST("Service is nil, check self.params")
    end

    if not service.name then
        return responses.send_HTTP_BAD_REQUEST("Bad service name")
    end

    if not service.type or not available_service_types[service.type] then
        return responses.send_HTTP_BAD_REQUEST("Bad service type")
    end

    if not service.enabled then
        service.enabled = false
    end

    service.id = utils.uuid()

    local _, err = dao_factory.service:insert(service)
    if err then
        return responses.send_HTTP_CONFLICT(err)
    end

    service.links = {
                self = self:build_url(self.req.parsed_url.path)
            }
    return responses.send_HTTP_CREATED({service = service})
end

function get_service_info(self, dao_factory)
    local service_id = self.params.service_id
    if not service_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad service_id")
    end

    local service, err = dao_factory.service:find({id = service_id})
    if not service then
        return responses.send_HTTP_BAD_REQUEST("Error: no such service in the system")
    end

    service.links = {
                self = self:build_url(self.req.parsed_url.path)
            }
    return responses.send_HTTP_OK({service = service})
end

function update_service(self, dao_factory)
    local service_id = self.params.service_id
    if not service_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad service_id")
    end

    local service, err = dao_factory.service:find({id = service_id})
    if not service then
        return responses.send_HTTP_BAD_REQUEST("Error: no such service in the system")
    end

    if not self.params.service then
        return responses.send_HTTP_BAD_REQUEST("Error: self.params.service is nil")
    end

    if self.params.service.type then
        if not available_service_types[self.params.service.type] then
            return responses.send_HTTP_BAD_REQUEST("Bad service type")
        end
    end

    local updated_service, err = dao_factory.service:update(self.params.service, {id = service_id})
    if err then
        return responses.send_HTTP_CONFLICT(err)
    end

    updated_service.links = {
                self = self:build_url(self.req.parsed_url.path)
            }

    return responses.send_HTTP_OK({service = updated_service})
end

function delete_service(self, dao_factory)
    local service_id = self.params.service_id
    if not service_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad service_id")
    end

    local service, err = dao_factory.service:find({id = service_id})
    if not service then
        return responses.send_HTTP_BAD_REQUEST("Error: no such service in the system")
    end

    local endpoints, err = dao_factory.endpoint:find_all({service_id = service_id})
    for i = 1, #endpoints do
        local _, err = dao_factory.endpoint:delete({id = endpoints[i].id})
        if err then
            return responses.send_HTTP_FORBIDDEN(err)
        end
    end

    local _, err = dao_factory.service:delete({id = service_id})
    return responses.send_HTTP_NO_CONTENT()
end

function list_endpoints(self, dao_factory)
    return ''
end

function create_endpoint(self, dao_factory)
    return ''
end

function get_endpoint_info(self, dao_factory)
    return ''
end

function update_endpoint(self, dao_factory)
    return ''
end

function delete_endpoint(self, dao_factory)
    return ''
end

ServiceAndEndpoint.list_services = list_services
ServiceAndEndpoint.create_service = create_service
ServiceAndEndpoint.get_service_info = get_service_info
ServiceAndEndpoint.update_service = update_service
ServiceAndEndpoint.delete_service = delete_service

ServiceAndEndpoint.list_endpoints = list_endpoints
ServiceAndEndpoint.create_endpoint = create_endpoint
ServiceAndEndpoint.get_endpoint_info = get_endpoint_info
ServiceAndEndpoint.update_endpoint = update_endpoint
ServiceAndEndpoint.delete_endpoint = delete_endpoint

return {
    ["/v3/services"] = {
        GET = function(self, dao_factory)
            ServiceAndEndpoint.list_services(self, dao_factory)
        end,
        POST = function(self, dao_factory)
            ServiceAndEndpoint.create_service(self, dao_factory)
        end
    },
    ["/v3/services/:service_id"] = {
        GET = function(self, dao_factory)
            ServiceAndEndpoint.get_service_info(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            ServiceAndEndpoint.update_service(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            ServiceAndEndpoint.delete_service(self, dao_factory)
        end
    },
    ["/v3/endpoints"] = {
        GET = function(self, dao_factory)
            ServiceAndEndpoint.list_endpoints(self, dao_factory)
        end,
        POST = function(self, dao_factory)
            ServiceAndEndpoint.create_endpoint(self, dao_factory)
        end
    },
    ["/v3/endpoints/:endpoint_id"] = {
        GET = function(self, dao_factory)
            ServiceAndEndpoint.get_endpoint_info(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            ServiceAndEndpoint.update_endpoint(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            ServiceAndEndpoint.delete_endpoint(self, dao_factory)
        end
    }
}