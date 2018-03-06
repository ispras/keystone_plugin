local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")

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