local views = {}

function add_routes(obj)
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

return views
