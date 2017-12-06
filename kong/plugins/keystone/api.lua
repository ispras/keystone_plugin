local views = {}

local function add_routes(obj)
    for k, v in pairs(obj) do
        views[k] = v
    end
end

local auth_and_tokens = require ("kong.plugins.keystone.views.auth_and_tokens")
add_routes(auth_and_tokens)

local credentials = require ("kong.plugins.keystone.views.credentials")
add_routes(credentials.routes)

local domain_configuration = require ("kong.plugins.keystone.views.domain_configuration")
add_routes(domain_configuration)

local domains = require ('kong.plugins.keystone.views.domains')
add_routes(domains)

local groups = require ('kong.plugins.keystone.views.groups')
add_routes(groups)

local os_inherit_api = require ('kong.plugins.keystone.views.os_inherit_api')
add_routes(os_inherit_api)

local os_pki_api = require ('kong.plugins.keystone.views.os_pki_api')
--add_routes(os_pki_api)

local project_tags = require ('kong.plugins.keystone.views.project_tags')
--add_routes(project_tags)

local projects = require ('kong.plugins.keystone.views.projects')
add_routes(projects)

local regions = require ('kong.plugins.keystone.views.regions')
add_routes(regions)

local roles = require ('kong.plugins.keystone.views.roles')
add_routes(roles.routes)

local services_and_endpoints = require ('kong.plugins.keystone.views.services_and_endpoints')
add_routes(services_and_endpoints.routes)

local users = require ('kong.plugins.keystone.views.users')
add_routes(users)

local v3 = require ('kong.plugins.keystone.views.v3')
add_routes(v3)

return views
