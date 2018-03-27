local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")
local cjson = require "cjson"

local available_interface_types = {
    public = true, internal = true, admin = true
}

local function list_endpoint_groups(self, dao_factory)
    local resp = {
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
        },
        endpoint_groups = {}
    }

    local endpoint_groups, err = dao_factory.endpoint_group:find_all()
    kutils.assert_dao_error(err, "endpoint_group:find_all")
    for i = 1, #endpoint_groups do
        endpoint_groups[i].links = {
                self = self:build_url(self.req.parsed_url.path)
        }
        endpoint_groups[i].filters = cjson.decode(endpoint_groups[i].filters)
        resp.endpoint_groups[i] = endpoint_groups[i]
    end

    return 200, resp
end

local function create_endpoint_group(self, dao_factory)
    if not self.params.endpoint_group then
        responses.send_HTTP_BAD_REQUEST("Bad endpoint group object")
    end

    if not self.params.endpoint_group.name or not self.params.endpoint_group.filters then
        responses.send_HTTP_BAD_REQUEST("Bad obligatory params")
    end

    local endpoint_group = self.params.endpoint_group
    local tmp, err = dao_factory.endpoint_group:find_all({name = endpoint_group.name})
    kutils.assert_dao_error(err, "endpoint_group:find_all")
    if next(tmp) then
        responses.send_HTTP_CONFLICT("Endpoint group object with this name already exists")
    end

    if endpoint_group.filters.interface and not available_interface_types[endpoint_group.filters.interface] then
        responses.send_HTTP_BAD_REQUEST("Bad interface type")
    end

    if endpoint_group.filters.service_id then
        local tmp, err = dao_factory.service:find({id = endpoint_group.filters.service_id})
        kutils.assert_dao_error(err, "service:find")
        if not tmp then
            responses.send_HTTP_BAD_REQUEST("No such service in the system")
        end
    end

    if endpoint_group.filters.region_id then
        local tmp, err = dao_factory.region:find({id = endpoint_group.region_id})
        kutils.assert_dao_error(err, "region:find")
        if not tmp then
            responses.send_HTTP_BAD_REQUEST("No such region in the system")
        end
    end

    endpoint_group.id = utils.uuid()
    endpoint_group.filters = cjson.encode(endpoint_group.filters)
    local _, err = dao_factory.endpoint_group:insert(endpoint_group)
    kutils.assert_dao_error(err, "endpoint_group:insert")
    endpoint_group.links = {
                self = self:build_url(self.req.parsed_url.path)
    }
    endpoint_group.filters = cjson.decode(endpoint_group.filters)
    return 201, {endpoint_group = endpoint_group}
end

local function get_endpoint_group(self, dao_factory)
    local endpoint_group_id = self.params.endpoint_group_id
    if not endpoint_group_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad endpoint group id")
    end

    local endpoint_group, err = dao_factory.endpoint_group:find({id = endpoint_group_id})
    kutils.assert_dao_error(err, "endpoint_group:find")
    if not endpoint_group then
        responses.send_HTTP_BAD_REQUEST("No such endpoint group in the system")
    end

    endpoint_group.links = {
                self = self:build_url(self.req.parsed_url.path)
    }
    endpoint_group.filters = cjson.decode(endpoint_group.filters)
    return 200, {endpoint_group = endpoint_group}
end

local function check_endpoint_group(self, dao_factory)
    local endpoint_group_id = self.params.endpoint_group_id
    if not endpoint_group_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad endpoint group id")
    end

    local endpoint_group, err = dao_factory.endpoint_group:find({id = endpoint_group_id})
    kutils.assert_dao_error(err, "endpoint_group:find")
    if not endpoint_group then
        responses.send_HTTP_BAD_REQUEST("No such endpoint group in the system")
    end

    return 200
end

local function update_endpoint_group(self, dao_factory)
    local endpoint_group_id = self.params.endpoint_group_id
    if not endpoint_group_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad endpoint group id")
    end

    local endpoint_group, err = dao_factory.endpoint_group:find({id = endpoint_group_id})
    kutils.assert_dao_error(err, "endpoint_group:find")
    if not endpoint_group then
        responses.send_HTTP_BAD_REQUEST("No such endpoint group in the system")
    end

    if not self.params.endpoint_group then
        responses.send_HTTP_BAD_REQUEST("Bad endpoint group object")
    end

    local update_params = {}
    if self.params.endpoint_group.name then
        update_params.name = self.params.endpoint_group.name
    end

    if self.params.endpoint_group.filters then
        if not available_interface_types[self.params.endpoint_group.filters.interface] then
            responses.send_HTTP_BAD_REQUEST("Bad interface type")
        end
        update_params.filters = cjson.encode(self.params.endpoint_group.filters)
    end

    if self.params.endpoint_group.description then
        update_params.descriprion = self.params.endpoint_group.description
    end

    local updated_endpoint_group, err = dao_factory.endpoint_group:update(update_params, {id = endpoint_group_id})
    kutils.assert_dao_error(err, "endpoint_group:update")

    updated_endpoint_group.links = {
        self = self:build_url(self.req.parsed_url.path)
    }
    updated_endpoint_group.filters = cjson.decode(updated_endpoint_group.filters)
    return 200, {endpoint_group = updated_endpoint_group}
end

local function delete_endpoint_group(self, dao_factory)
    local endpoint_group_id = self.params.endpoint_group_id
    if not endpoint_group_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad endpoint group id")
    end

    local endpoint_group, err = dao_factory.endpoint_group:find({id = endpoint_group_id})
    kutils.assert_dao_error(err, "endpoint_group:find")
    if not endpoint_group then
        responses.send_HTTP_BAD_REQUEST("No such endpoint group in the system")
    end

    local _, err = dao_factory.endpoint_group:delete({id = endpoint_group_id})
    kutils.assert_dao_error(err, "endpoint_group:delete")

    return 204
end

local function create_association(self, dao_factory)
    if not self.params.endpoint_id or not self.params.project_id then
        responses.send_HTTP_BAD_REQUEST("Bad obligatory params")
    end
    local endpoint_id, project_id = self.params.endpoint_id, self.params.project_id

    local endpoint, err = dao_factory.endpoint:find({id = endpoint_id})
    kutils.assert_dao_error(err, "endpoint:find")
    if not endpoint then
        responses.send_HTTP_BAD_REQUEST("No such endpoint in the system")
    end

    local project, err = dao_factory.project:find({id = project_id})
    kutils.assert_dao_error(err, "project:find")
    if not project then
        responses.send_HTTP_BAD_REQUEST("No such project in the system")
    end

    local association, err = dao_factory.project_endpoint:find({endpoint_id = endpoint_id, project_id = project_id})
    kutils.assert_dao_error(err, "project_endpoint:find")
    if association then
        responses.send_HTTP_CONFLICT("Such project endpoint association already exists")
    end

    local _, err = dao_factory.project_endpoint:insert({endpoint_id = endpoint_id, project_id = project_id})
    kutils.assert_dao_error(err, "project_endpoint:insert")

    return 204
end

local function check_association(self, dao_factory)
    if not self.params.endpoint_id or not self.params.project_id then
        responses.send_HTTP_BAD_REQUEST("Bad obligatory params")
    end
    local endpoint_id, project_id = self.params.endpoint_id, self.params.project_id

    local association, err = dao_factory.project_endpoint:find({endpoint_id = endpoint_id, project_id = project_id})
    kutils.assert_dao_error(err, "project_endpoint:find")
    if not association then
        responses.send_HTTP_BAD_REQUEST("No such project endpoint association in the system")
    end

    return 204
end

local function delete_association(self, dao_factory)
    if not self.params.endpoint_id or not self.params.project_id then
        responses.send_HTTP_BAD_REQUEST("Bad obligatory params")
    end
    local endpoint_id, project_id = self.params.endpoint_id, self.params.project_id

    local association, err = dao_factory.project_endpoint:find({endpoint_id = endpoint_id, project_id = project_id})
    kutils.assert_dao_error(err, "project_endpoint:find")
    if not association then
        responses.send_HTTP_BAD_REQUEST("No such project endpoint association in the system")
    end

    local _, err = dao_factory.project_endpoint:delete({endpoint_id = endpoint_id, project_id = project_id})
    kutils.assert_dao_error(err, "project_endpoint:delete")

    return 204
end

local function list_associations_by_project(self, dao_factory)
    if not  self.params.project_id then
        responses.send_HTTP_BAD_REQUEST("Bad project id")
    end

    local resp = {
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
        },
        endpoints = {}
    }

    local associations, err = dao_factory.project_endpoint:find_all({project_id = self.params.project_id})
    kutils.assert_dao_error(err, "project_endpoint:find_all")

    local j = 1
    for i = 1, #associations do
        local endpoint, err = dao_factory.endpoint:find({id = associations[i].endpoint_id})
        kutils.assert_dao_error(err, "endpoint:find")

        if endpoint then
            endpoint.links = {
                self = self:build_url(self.req.parsed_url.path)
            }
            resp.endpoints[j] = endpoint
            j = j + 1
        end
    end

   return 200, resp
end

local function list_associations_by_endpoint(self, dao_factory)
    if not  self.params.endpoint_id then
        responses.send_HTTP_BAD_REQUEST("Bad endpoint id")
    end

    local resp = {
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
        },
        projects = {}
    }

    local associations, err = dao_factory.project_endpoint:find_all({endpoint_id = self.params.endpoint_id})
    kutils.assert_dao_error(err, "project_endpoint:find_all")

    local j = 1
    for i = 1, #associations do
        local project, err = dao_factory.project:find({id = associations[i].project_id})
        kutils.assert_dao_error(err, "project:find")

        if project then
            project.links = {
                self = self:build_url(self.req.parsed_url.path)
            }
            resp.projects[j] = project
            j = j + 1
        end
    end

   return 200, resp
end

local function create_ep_to_project_association(self, dao_factory)
    if not self.params.endpoint_group_id or not self.params.project_id then
        responses.send_HTTP_BAD_REQUEST("Bad obligatory params")
    end
    local endpoint_group_id, project_id = self.params.endpoint_group_id, self.params.project_id

    local endpoint_group, err = dao_factory.endpoint_group:find({id = endpoint_group_id})
    kutils.assert_dao_error(err, "endpoint_group:find")
    if not endpoint_group then
        responses.send_HTTP_BAD_REQUEST("No such endpoint group in the system")
    end

    local project, err = dao_factory.project:find({id = project_id})
    kutils.assert_dao_error(err, "project:find")
    if not project then
        responses.send_HTTP_BAD_REQUEST("No such project in the system")
    end

    local association, err = dao_factory.project_endpoint_group:find({endpoint_group_id = endpoint_group_id,
                                                                        project_id = project_id})
    kutils.assert_dao_error(err, "project_endpoint_group:find_all")

    if association then
        responses.send_HTTP_CONFLICT("Such project endpoint group association already exists")
    end

    local _, err = dao_factory.project_endpoint_group:insert({endpoint_group_id = endpoint_group_id, project_id = project_id})
    kutils.assert_dao_error(err, "project_endpoint_group:insert")

    return 204
end

local function get_ep_to_project_association(self, dao_factory)
    if not self.params.endpoint_group_id or not self.params.project_id then
        responses.send_HTTP_BAD_REQUEST("Bad obligatory params")
    end
    local endpoint_group_id = self.params.endpoint_group_id
    local project_id = self.params.project_id

    local endpoint_group, err = dao_factory.endpoint_group:find({id = endpoint_group_id})
    kutils.assert_dao_error(err, "endpoint_group:find")
    if not endpoint_group then
        responses.send_HTTP_BAD_REQUEST("No such endpoint group in the system")
    end

    local project, err = dao_factory.project:find({id = project_id})
    kutils.assert_dao_error(err, "project:find")
    if not project then
        responses.send_HTTP_BAD_REQUEST("No such project in the system")
    end

    local association, err = dao_factory.project_endpoint_group:find({endpoint_group_id = endpoint_group_id, project_id = project_id})
    kutils.assert_dao_error(err, "project_endpoint_group:find")
    if not association then
        responses.send_HTTP_BAD_REQUEST("No such project endpoint group association in the system")
    end

    project.links = {
                self = self:build_url(self.req.parsed_url.path)
    }

    return 200, {project = project}
end

local function check_ep_to_project_association(self, dao_factory)
    if not self.params.endpoint_group_id or not self.params.project_id then
        responses.send_HTTP_BAD_REQUEST("Bad obligatory params")
    end
    local endpoint_group_id = self.params.endpoint_group_id
    local project_id = self.params.project_id

    local endpoint_group, err = dao_factory.endpoint_group:find({id = endpoint_group_id})
    kutils.assert_dao_error(err, "endpoint_group:find")
    if not endpoint_group then
        responses.send_HTTP_BAD_REQUEST("No such endpoint group in the system")
    end

    local project, err = dao_factory.project:find({id = project_id})
    kutils.assert_dao_error(err, "project:find")
    if not project then
        responses.send_HTTP_BAD_REQUEST("No such project in the system")
    end

    local association, err = dao_factory.project_endpoint_group:find({endpoint_group_id = endpoint_group_id, project_id = project_id})
    kutils.assert_dao_error(err, "project_endpoint_group:find")
    if not association then
        responses.send_HTTP_BAD_REQUEST("No such project endpoint group association in the system")
    end

    return 200
end

local function delete_ep_to_project_association(self, dao_factory)
    if not self.params.endpoint_group_id or not self.params.project_id then
        responses.send_HTTP_BAD_REQUEST("Bad obligatory params")
    end
    local endpoint_group_id = self.params.endpoint_group_id
    local project_id = self.params.project_id

    local endpoint_group, err = dao_factory.endpoint_group:find({id = endpoint_group_id})
    kutils.assert_dao_error(err, "endpoint_group:find")
    if not endpoint_group then
        responses.send_HTTP_BAD_REQUEST("No such endpoint group in the system")
    end

    local project, err = dao_factory.project:find({id = project_id})
    kutils.assert_dao_error(err, "project:find")
    if not project then
        responses.send_HTTP_BAD_REQUEST("No such project in the system")
    end

    local association, err = dao_factory.project_endpoint_group:find({endpoint_group_id = endpoint_group_id, project_id = project_id})
    kutils.assert_dao_error(err, "project_endpoint_group:find")
    if not association then
        responses.send_HTTP_BAD_REQUEST("No such project endpoint group association in the system")
    end

    local association, err = dao_factory.project_endpoint_group:delete({endpoint_group_id = endpoint_group_id, project_id = project_id})
    kutils.assert_dao_error(err, "project_endpoint_group:delete")

    return 204
end

local function list_projects_by_endpoint_group(self, dao_factory)
    if not  self.params.endpoint_group_id then
        responses.send_HTTP_BAD_REQUEST("Bad endpoint group id")
    end

    local resp = {
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
        },
        projects = {}
    }

    local associations, err = dao_factory.project_endpoint_group:find_all({endpoint_group_id = self.params.endpoint_group_id})
    kutils.assert_dao_error(err, "project_endpoint_group:find_all")

    local j = 1
    for i = 1, #associations do
        local project, err = dao_factory.project:find({id = associations[i].project_id})
        kutils.assert_dao_error(err, "project:find")

        if project then
            project.links = {
                self = self:build_url(self.req.parsed_url.path)
            }
            resp.projects[j] = project
            j = j + 1
        end
    end

   return 200, resp
end

local function list_endpoints_by_endpoint_group(self, dao_factory)
    if not  self.params.endpoint_group_id then
        responses.send_HTTP_BAD_REQUEST("Bad endpoint group id")
    end

    local resp = {
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
        },
        endpoints = {}
    }

    local endpoint_group, err = dao_factory.endpoint_group:find({id = self.params.endpoint_group_id})
    kutils.assert_dao_error(err, "endpoint_group:find")

    if not endpoint_group then
        responses.send_HTTP_BAD_REQUEST("No such endpoint group in the system")
    end

    local endpoints, err = dao_factory.endpoint:find_all(cjson.decode(endpoint_group.filters))
    kutils.assert_dao_error(err, "endpoint:find_all")

    for i = 1, #endpoints do
        endpoints[i].links = {
            self = self:build_url(self.req.parsed_url.path)
        }
        resp.endpoints[i] = endpoints[i]
    end

   return 200, resp
end

local function list_endpoint_groups_by_project(self, dao_factory)
    if not  self.params.project_id then
        responses.send_HTTP_BAD_REQUEST("Bad project id")
    end

    local resp = {
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
        },
        endpoint_groups = {}
    }

    local associations, err = dao_factory.project_endpoint_group:find_all({project_id = self.params.project_id})
    kutils.assert_dao_error(err, "project_endpoint_group:find_all")

    local j = 1
    for i = 1, #associations do
        local endpoint_group, err = dao_factory.endpoint_group:find({id = associations[i].endpoint_group_id})
        kutils.assert_dao_error(err, "endpoint_group:find")

        if endpoint_group then
            endpoint_group.links = {
                self = self:build_url(self.req.parsed_url.path)
            }
            endpoint_group.filters = cjson.decode(endpoint_group.filters)
            resp.endpoint_groups[j] = endpoint_group
            j = j + 1
        end
    end

   return 200, resp
end

local routes = {
    ['/v3/OS-EP-FILTER/endpoint_groups'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_endpoint_groups", dao_factory, self.params)
            responses.send(list_endpoint_groups(self, dao_factory))
        end,
        POST = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_endpoint_group", dao_factory, self.params)
            responses.send(create_endpoint_group(self, dao_factory))
        end
    },
    ['/v3/OS-EP-FILTER/endpoint_groups/:endpoint_group_id'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_endpoint_group", dao_factory, self.params)
            responses.send(get_endpoint_group(self, dao_factory))
        end,
        HEAD = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:check_endpoint_group", dao_factory, self.params)
            responses.send(check_endpoint_group(self, dao_factory))
        end,
        PATCH = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:update_endpoint_group", dao_factory, self.params)
            responses.send(update_endpoint_group(self, dao_factory))
        end,
        DELETE = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_endpoint_group", dao_factory, self.params)
            responses.send(delete_endpoint_group(self, dao_factory))
        end
    },
    ['/v3/OS-EP-FILTER/projects/:project_id/endpoints/:endpoint_id'] = {
        PUT = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_association", dao_factory, self.params)
            responses.send(create_association(self, dao_factory))
        end,
        HEAD = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:check_association", dao_factory, self.params)
            responses.send(check_association(self, dao_factory))
        end,
        DELETE = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_association", dao_factory, self.params)
            responses.send(delete_association(self, dao_factory))
        end
    },
    ['/v3/OS-EP-FILTER/projects/:project_id/endpoints'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_associations_by_project", dao_factory, self.params)
            responses.send(list_associations_by_project(self, dao_factory))
        end
    },
    ['/v3/OS-EP-FILTER/endpoints/:endpoint_id/projects'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_associations_by_endpoint", dao_factory, self.params)
            responses.send(list_associations_by_endpoint(self, dao_factory))
        end
    },
    ['/v3/OS-EP-FILTER/endpoint_groups/:endpoint_group_id/projects/:project_id'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_ep_to_project_association", dao_factory, self.params)
            responses.send(get_ep_to_project_association(self, dao_factory))
        end,
        PUT = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_ep_to_project_association", dao_factory, self.params)
            responses.send(create_ep_to_project_association(self, dao_factory))
        end,
        HEAD = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:check_ep_to_project_association", dao_factory, self.params)
            responses.send(check_ep_to_project_association(self, dao_factory))
        end,
        DELETE = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_ep_to_project_association", dao_factory, self.params)
            responses.send(delete_ep_to_project_association(self, dao_factory))
        end,
    },
    ['/v3/OS-EP-FILTER/endpoint_groups/:endpoint_group_id/projects'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_projects_by_endpoint_group", dao_factory, self.params)
            responses.send(list_projects_by_endpoint_group(self, dao_factory))
        end
    },
    ['/v3/OS-EP-FILTER/endpoint_groups/:endpoint_group_id/endpoints'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_endpoints_by_endpoint_group", dao_factory, self.params)
            responses.send(list_endpoints_by_endpoint_group(self, dao_factory))
        end
    },
    ['/v3/OS-EP-FILTER/projects/:project_id/endpoint_groups'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_endpoint_groups_by_project", dao_factory, self.params)
            responses.send(list_endpoint_groups_by_project(self, dao_factory))
        end
    }
}

return routes