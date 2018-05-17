local views = {}

local function add_routes(obj)
    for k, v in pairs(obj) do
        views[k] = v
    end
end

local auth_routes = require ("kong.plugins.keystone.views.auth_routes")
add_routes(auth_routes)

local auth_and_tokens = require ("kong.plugins.keystone.views.auth_and_tokens")
add_routes(auth_and_tokens.routes)

local credentials = require ("kong.plugins.keystone.views.credentials")
add_routes(credentials.routes)

local domain_configuration = require ("kong.plugins.keystone.views.domain_configuration")
add_routes(domain_configuration)

local domains = require ('kong.plugins.keystone.views.domains')
add_routes(domains.routes)

local groups = require ('kong.plugins.keystone.views.groups')
add_routes(groups.routes)

--local os_inherit_api = require ('kong.plugins.keystone.views.os_inherit_api')
--add_routes(os_inherit_api)

--local os_pki_api = require ('kong.plugins.keystone.views.os_pki_api')
--add_routes(os_pki_api)

--local project_tags = require ('kong.plugins.keystone.views.project_tags')
--add_routes(project_tags)

local projects = require ('kong.plugins.keystone.views.projects')
add_routes(projects.routes)

local regions = require ('kong.plugins.keystone.views.regions')
add_routes(regions)

local roles = require ('kong.plugins.keystone.views.roles')
add_routes(roles.routes)

local services_and_endpoints = require ('kong.plugins.keystone.views.services_and_endpoints')
add_routes(services_and_endpoints.routes)

local users = require ('kong.plugins.keystone.views.users')
add_routes(users.routes)

local v3 = require ('kong.plugins.keystone.views.v3')
add_routes(v3)

local fkeys = require ('kong.plugins.keystone.views.fernet_keys')
add_routes(fkeys.routes)


local os_endpoint_policy = require ('kong.plugins.keystone.extensions.os_endpoint_policy')
add_routes(os_endpoint_policy)

local policies = require ('kong.plugins.keystone.views.policies')
add_routes(policies)

--local os_federation = require('kong.plugins.keystone.extensions.os_federation')
--add_routes(os_federation.routes)

local os_oauth2 = require('kong.plugins.keystone.extensions.os_oauth2')
add_routes(os_oauth2.routes)

local os_trust = require('kong.plugins.keystone.extensions.os_trust')
add_routes(os_trust.routes)

local os_ep_filter = require("kong.plugins.keystone.extensions.os_ep_filter")
add_routes(os_ep_filter)

local os_revoke = require("kong.plugins.keystone.extensions.os_revoke")
add_routes(os_revoke.routes)

local os_simple_cert = require("kong.plugins.keystone.extensions.os_simple_cert")
add_routes(os_simple_cert.routes)

return views
