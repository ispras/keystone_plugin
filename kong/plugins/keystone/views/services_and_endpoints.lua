local responses = require "kong.tools.responses"
local crud = require "kong.api.crud_helpers"
local cjson = require "cjson"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")

local ServiceAndEndpoint = {}

local available_interface_types = {
    public = true, internal = true, admin = true
}

local function list_services(self, dao_factory, enabled)
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
    local args = (self.params.type or enabled) and {type = self.params.type, enabled = enabled} or nil
    services, err = dao_factory.service:find_all(args)

    kutils.assert_dao_error(err, "service find_all")

    for i = 1, #services do
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
    return resp
end

local function check_service(dao_factory, name, type)
    local res, err = dao_factory.service:find_all({name = name, type = type})
    kutils.assert_dao_error(err, "service find_all")
    if next(res) then
         return responses.send_HTTP_BAD_REQUEST("Error: service with this name and type already exists")
    end
end

local function create_service(self, dao_factory)
    local service = self.params.service
    if not service then
        return responses.send_HTTP_BAD_REQUEST("Service is nil, check self.params")
    end

    if not service.name then
        return responses.send_HTTP_BAD_REQUEST("Bad service name")
    end

    if not service.type then
        return responses.send_HTTP_BAD_REQUEST("Bad service type")
    end

    if not service.enabled then
        service.enabled = false
    end

    service.id = utils.uuid()

    check_service(dao_factory, service.name, service.type)
    local _, err = dao_factory.service:insert(service)
    kutils.assert_dao_error(err, "service insert")

    service.links = {
                self = self:build_url(self.req.parsed_url.path)
            }
    return responses.send_HTTP_CREATED({service = service})
end

local function get_service_info(self, dao_factory)
    local service_id = self.params.service_id
    if not service_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad service_id")
    end

    local service, err = dao_factory.service:find({id = service_id})
    kutils.assert_dao_error(err, "service find")
    if not service then
        service, err = dao_factory.service:find_all({name=service_id})
        kutils.assert_dao_error(err, "service find_all")
        if not next(service) then
            return responses.send_HTTP_BAD_REQUEST("Error in get info: no such service in the system")
        end
        service = service[1]
    end

    service.links = {
                self = self:build_url(self.req.parsed_url.path)
            }
    return {service = service}
end

local function update_service(self, dao_factory)
    local service_id = self.params.service_id
    if not service_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad service_id")
    end

    local service, err = dao_factory.service:find({id = service_id})
    kutils.assert_dao_error(err, "service find")
    if not service then
        return responses.send_HTTP_BAD_REQUEST("Error in update: no such service in the system")
    end

    if not self.params.service then
        return responses.send_HTTP_BAD_REQUEST("Error: self.params.service is nil")
    end

    if self.params.service.name and not self.params.service.type then
        check_service(dao_factory, self.params.service.name, service.type)
    elseif self.params.service.type and not self.params.service.name then
        check_service(dao_factory, service.name, self.params.service.type)
    elseif self.params.service.type and self.params.service.name then
        check_service(dao_factory, self.params.service.name, self.params.service.type)
    end

    local updated_service, err = dao_factory.service:update(self.params.service, {id = service_id})
    kutils.assert_dao_error(err, "service update")

    updated_service.links = {
                self = self:build_url(self.req.parsed_url.path)
            }

    return responses.send_HTTP_OK({service = updated_service})
end

local function delete_service(self, dao_factory)
    local service_id = self.params.service_id
    if not service_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad service_id")
    end

    local service, err = dao_factory.service:find({id = service_id})
    kutils.assert_dao_error(err, "service find")
    if not service then
        return responses.send_HTTP_BAD_REQUEST("Error with delete: no such service in the system")
    end

    local endpoints, err = dao_factory.endpoint:find_all({service_id = service_id})
    kutils.assert_dao_error(err, "endpoint find_all")
    for i = 1, #endpoints do
        local _, err = dao_factory.endpoint:delete({id = endpoints[i].id})
        kutils.assert_dao_error(err, "endpoint delete")
    end

    local _, err = dao_factory.service:delete({id = service_id})
    kutils.assert_dao_error(err, "service delete")
    return responses.send_HTTP_NO_CONTENT()
end

local function list_endpoints(self, dao_factory, enabled)
    local resp = {
        links = {
            next = "null",
            previous = "null",
            self = self:build_url(self.req.parsed_url.path)
        },
        endpoints = {}
    }

    local args = {enabled = enabled}
    if self.params.interface then
        if not available_interface_types[self.params.interface] then
            return responses.send_HTTP_BAD_REQUEST("Error: bad endpoint interface")
        end
        args.interface = self.params.interface
    end

    if self.params.service_id then
        local service, err = dao_factory.service:find({id = self.params.service_id})
        kutils.assert_dao_error(err, "service find")
        if not service then
            return responses.send_HTTP_BAD_REQUEST("Error in list endpoints: no such service in the system")
        end
        args.service_id = self.params.service_id
    end

    local endpoints = {}
    local err
    if next(args) then
        endpoints, err = dao_factory.endpoint:find_all(args)
    else
        endpoints, err = dao_factory.endpoint:find_all()
    end

    kutils.assert_dao_error(err, "endpoint find_all")

    for i = 1, #endpoints do
        resp.endpoints[i] = {}
        resp.endpoints[i].region_id = endpoints[i].region_id
        resp.endpoints[i].id = endpoints[i].id
        resp.endpoints[i].links = {
                self = self:build_url(self.req.parsed_url.path)
        }
        resp.endpoints[i].enabled = endpoints[i].enabled
        resp.endpoints[i].url = endpoints[i].url
        resp.endpoints[i].interface = endpoints[i].interface
        resp.endpoints[i].service_id = endpoints[i].service_id
    end
    return resp
end

local function check_endpoint(dao_factory, interface, service_id, region_id)
    local res, err = dao_factory.endpoint:find_all({interface = interface, service_id = service_id, region_id = region_id})
    kutils.assert_dao_error(err, "endpoint find_all")

    if next(res) then
        return responses.send_HTTP_BAD_REQUEST("Error: endpoint with this service ID, region ID and interface already exists")
    end
end

local function create_endpoint(self, dao_factory)
    local endpoint = self.params.endpoint
    if not endpoint then
        return responses.send_HTTP_BAD_REQUEST("endpoint is nil, check self.params")
    end

    if not endpoint.url then
        return responses.send_HTTP_BAD_REQUEST("Error: bad endpoint url")
    end

    if not endpoint.enabled then
        endpoint.enabled = true
    end

    if not endpoint.interface or not available_interface_types[endpoint.interface] then
        return responses.send_HTTP_BAD_REQUEST("Error: bad endpoint interface")
    end

    if not endpoint.service_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad endpoint service_id")
    end

    local service, err = dao_factory.service:find({id = endpoint.service_id})
    kutils.assert_dao_error(err, "service find")
    if not service or err then
        return responses.send_HTTP_BAD_REQUEST("Error in create endpoint: no such service in the system")
    end

    if endpoint.region_id then
        local region, err = dao_factory.region:find({id = endpoint.region_id})
        kutils.assert_dao_error(err, "region find")
        if not region or err then
            return responses.send_HTTP_BAD_REQUEST("Error: no such region in the system")
        end
    end

    check_endpoint(dao_factory, endpoint.interface, endpoint.service_id, endpoint.region_id)

    if not endpoint.id then
        endpoint.id = utils.uuid()
    end
    local _, err = dao_factory.endpoint:insert(endpoint)
    kutils.assert_dao_error(err, "endpoint insert")

    endpoint.links = {
                self = self:build_url(self.req.parsed_url.path)
    }

    return responses.send_HTTP_CREATED({endpoint = endpoint})
end

local function get_endpoint_info(self, dao_factory)
    local endpoint_id = self.params.endpoint_id
    if not endpoint_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad endpoint_id")
    end

    local endpoint, err = dao_factory.endpoint:find({id = endpoint_id})
    kutils.assert_dao_error(err, "endpoint find")
    if not endpoint then
        return responses.send_HTTP_BAD_REQUEST("Error: no such endpoint in the system")
    end

    endpoint.links = {
                self = self:build_url(self.req.parsed_url.path)
            }
    return {endpoint = endpoint}
end

local function update_endpoint(self, dao_factory)
    local endpoint_id = self.params.endpoint_id
    if not endpoint_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad endpoint_id")
    end

    local endpoint, err = dao_factory.endpoint:find({id = endpoint_id})
    kutils.assert_dao_error(err, "endpoint find")
    if not endpoint then
        return responses.send_HTTP_BAD_REQUEST("Error: no such endpoint in the system")
    end

    local new_endpoint = self.params.endpoint
    if not new_endpoint then
        return responses.send_HTTP_BAD_REQUEST("endpoint is nil, check self.params")
    end

    if new_endpoint.interface then
        if not available_interface_types[new_endpoint.interface] then
            return responses.send_HTTP_BAD_REQUEST("Error: bad endpoint interface")
        end
    end

    if new_endpoint.service_id then
       local service, err = dao_factory.service:find({id = new_endpoint.service_id})
        kutils.assert_dao_error(err, "service find")
        if not service then
            return responses.send_HTTP_BAD_REQUEST("Error in update endpoint: no such service in the system")
        end
    end

    if new_endpoint.region_id then
        local region, err = dao_factory.region:find({id = endpoint.region_id})
        kutils.assert_dao_error(err, "region find")
        if not region then
            return responses.send_HTTP_BAD_REQUEST("Error: no such region in the system")
        end
    end

    if new_endpoint.region_id or new_endpoint.service_id or new_endpoint.interface then
        check_endpoint(dao_factory, new_endpoint.interface or endpoint.interface,
            new_endpoint.service_id or endpoint.service_id,
            new_endpoint.region_id or endpoint.region_id)
    end

    local updated_endpoint, err = dao_factory.endpoint:update(new_endpoint, {id = endpoint_id})
    kutils.assert_dao_error(err, "endpoint update")

    if not updated_endpoint or err then
        return responses.send_HTTP_CONFLICT(err)
    end

    updated_endpoint.links = {
                self = self:build_url(self.req.parsed_url.path)
            }
    return responses.send_HTTP_OK({endpoint = updated_endpoint})
end

local function delete_endpoint(self, dao_factory)
    local endpoint_id = self.params.endpoint_id
    if not endpoint_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad endpoint_id")
    end

    local endpoint, err = dao_factory.endpoint:find({id = endpoint_id})
    kutils.assert_dao_error(err, "endpoint find")
    if not endpoint then
        return responses.send_HTTP_NOT_FOUND("Error: no such endpoint in the system")
    end

    local _, err = dao_factory.endpoint:delete({id = endpoint_id})
    kutils.assert_dao_error(err, "endpoint delete")

    return responses.send_HTTP_NO_CONTENT()
end

local Service = {
    list = list_services,
    get_info = get_service_info
}
local Endpoint = {
    list = list_endpoints,
    get_info = get_endpoint_info
}

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

local routes = {
    ["/v3/services"] = {
        GET = function(self, dao_factory)
            responses.send_HTTP_OK(ServiceAndEndpoint.list_services(self, dao_factory))
        end,
        POST = function(self, dao_factory)
            ServiceAndEndpoint.create_service(self, dao_factory)
        end
    },
    ["/v3/services/:service_id"] = {
        GET = function(self, dao_factory)
            responses.send_HTTP_OK(ServiceAndEndpoint.get_service_info(self, dao_factory))
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
            responses.send_HTTP_OK(ServiceAndEndpoint.list_endpoints(self, dao_factory))
        end,
        POST = function(self, dao_factory)
            ServiceAndEndpoint.create_endpoint(self, dao_factory)
        end
    },
    ["/v3/endpoints/:endpoint_id"] = {
        GET = function(self, dao_factory)
            responses.send_HTTP_OK(ServiceAndEndpoint.get_endpoint_info(self, dao_factory))
        end,
        PATCH = function(self, dao_factory)
            ServiceAndEndpoint.update_endpoint(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            ServiceAndEndpoint.delete_endpoint(self, dao_factory)
        end
    }
}

routes["/identity/v3/endpoints/"] = routes["/v3/endpoints"]

return {routes = routes, services = Service, endpoints = Endpoint}