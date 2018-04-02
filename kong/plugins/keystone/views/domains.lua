local temp = require ("kong.plugins.keystone.views.projects")
local projects = temp.routes
local policies = require ("kong.plugins.keystone.policies")

local function list_domains(self, dao_factory)
    return ''
end

local function create_domain(self, dao_factory)
    return ''
end

local function get_domain_info(self, dao_factory)
    return ''
end

local function update_domain(self, dao_factory)
    return ''
end

local function delete_domain(self, dao_factory)
    return ''
end

local function update_params(params)
    params.project = {}
    if params.domain then
        params.project = params.domain
    end
    params.project.is_domain = true
    params.domain = true
end

local routes = {
    ["/v3/domains"] = {
        GET = function (self, dao_factory)
            self.params.is_domain = true
            self.params.domain = true
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_domains", dao_factory, self.params)
            projects["/v3/projects"].GET(self, dao_factory)
        end,
        POST = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_domain", dao_factory, self.params)
            update_params(self.params)
            projects["/v3/projects"].POST(self, dao_factory)
        end
    },
    ["/v3/domains/:project_id"] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_domain", dao_factory, self.params)
            update_params(self.params)
            projects["/v3/projects/:project_id"].GET(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:update_domain", dao_factory, self.params)
            update_params(self.params)
            projects["/v3/projects/:project_id"].PATCH(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_domain", dao_factory, self.params)
            projects["/v3/projects/:project_id"].DELETE(self, dao_factory)
        end
    }
}
return {
    routes = routes
}