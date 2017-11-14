local views = {}

local function add_routes(obj)
    for k, v in pairs(obj) do
        views[k] = v
    end
end

local users = require ('kong.plugins.keystone.views.users')
add_routes(users)

local projects = require ('kong.plugins.keystone.views.projects')
add_routes(projects)

local domains = require ('kong.plugins.keystone.views.domains')
add_routes(domains)

local regions = require ('kong.plugins.keystone.views.regions')
add_routes(regions)

local services_and_endpoints = require ('kong.plugins.keystone.views.services_and_endpoints')
add_routes(services_and_endpoints)

local auth_and_tokens = require ("kong.plugins.keystone.views.auth_and_tokens")
add_routes(auth_and_tokens)

return views
