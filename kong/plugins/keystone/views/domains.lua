local responses = require "kong.tools.responses"
local uuid4 = require('uuid4')
local sha512 = require('sha512')
local projects = require ("kong.plugins.keystone.views.projects")

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
    if params.domain then
        params.domain.is_domain = true
    end
    params.project = params.domain
    params.domain = nil
end

return {
    ["/v3/domains"] = {
        GET = function (self, dao_factory)
            update_params(self.params)
            projects["/v3/projects"].GET(self, dao_factory)
        end,
        POST = function (self, dao_factory)
            update_params(self.params)
            projects["/v3/projects"].POST(self, dao_factory)
        end
    },
    ["/v3/domains/:project_id"] = {
        GET = function (self, dao_factory)
            update_params(self.params)
            projects["/v3/projects/:project_id"].GET(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            update_params(self.params)
            projects["/v3/projects/:project_id"].PATCH(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            update_params(self.params)
            projects["/v3/projects/:project_id"].DELETE(self, dao_factory)
        end
    }
}