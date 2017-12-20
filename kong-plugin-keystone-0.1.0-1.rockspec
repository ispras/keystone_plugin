package = "kong-plugin-keystone"  -- TODO: rename, must match the info in the filename of this rockspec!
                                  -- as a convention; stick to the prefix: `kong-plugin-`
version = "0.1.0-1"               -- TODO: renumber, must match the info in the filename of this rockspec!
-- The version '0.1.0' is the source code version, the trailing '1' is the version of this rockspec.
-- whenever the source version changes, the rockspec should be reset to 1. The rockspec version is only
-- updated (incremented) when this file changes, but the source remains the same.

supported_platforms = {"linux", "macosx"}
source = {
  -- these are initially not required to make it work
  url = "git://github.com/Mashape/kong_plugin",
  tag = "0.1.0"
}

description = {
  summary = "Kong is a scalable and customizable API Management Layer built on top of Nginx.",
  homepage = "http://getkong.org",
  license = "MIT"
}

dependencies = {
  "luasec == 0.6",
  "luasocket == 3.0-rc1",
  "penlight == 1.5.4",
  "lua-resty-http == 0.08",
  "lua-resty-jit-uuid == 0.0.5",
  "multipart == 0.5.1",
  "version == 0.2",
  "kong-lapis == 1.6.0.1",
  "lua-cassandra == 1.2.3",
  "pgmoon == 1.8.0",
  "luatz == 0.3",
  "lua_system_constants == 0.1.2",
  "lua-resty-iputils == 0.3.0",
  "luacrypto == 0.3.2",
  "luasyslog == 1.0.0",
  "lua_pack == 1.0.5",
  "lua-resty-dns-client == 0.6.2",
  "lua-resty-worker-events == 0.3.0",
  "lua-resty-mediador == 0.1.2",
  "luaposix == 33.4.0-1"
}

local pluginName = "keystone"  -- TODO: rename. This is the name to set in the Kong configuration `custom_plugins` setting.
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.keystone.migrations.cassandra"] = "kong/plugins/keystone/migrations/cassandra.lua",
    ["kong.plugins.keystone.handler"] = "kong/plugins/keystone/handler.lua",
    ["kong.plugins.keystone.schema"] = "kong/plugins/keystone/schema.lua",
    ["kong.plugins.keystone.api"] = "kong/plugins/keystone/api.lua",
    ["kong.plugins.keystone.daos"] = "kong/plugins/keystone/daos.lua",
    ["kong.plugins.keystone.sha512"] = "kong/plugins/keystone/sha512.lua",
    ["kong.plugins.keystone.uuid4"] = "kong/plugins/keystone/uuid4.lua",
    ["kong.plugins.keystone.redis"] = "kong/plugins/keystone/redis.lua",
    ["kong.plugins.keystone.policies"] = "kong/plugins/keystone/policies.lua",
    ["kong.plugins.keystone.views.users"] = "kong/plugins/keystone/views/users.lua",
    ["kong.plugins.keystone.views.services_and_endpoints"] = "kong/plugins/keystone/views/services_and_endpoints.lua",
    ["kong.plugins.keystone.views.roles"] = "kong/plugins/keystone/views/roles.lua",
    ["kong.plugins.keystone.views.regions"] = "kong/plugins/keystone/views/regions.lua",
    ["kong.plugins.keystone.views.projects"] = "kong/plugins/keystone/views/projects.lua",
    ["kong.plugins.keystone.views.project_tags"] = "kong/plugins/keystone/views/project_tags.lua",
    ["kong.plugins.keystone.views.os_pki_api"] = "kong/plugins/keystone/views/os_pki_api.lua",
    ["kong.plugins.keystone.views.os_inherit_api"] = "kong/plugins/keystone/views/os_inherit_api.lua",
    ["kong.plugins.keystone.views.groups"] = "kong/plugins/keystone/views/groups.lua",
    ["kong.plugins.keystone.views.domains"] = "kong/plugins/keystone/views/domains.lua",
    ["kong.plugins.keystone.views.domain_configuration"] = "kong/plugins/keystone/views/domain_configuration.lua",
    ["kong.plugins.keystone.views.credentials"] = "kong/plugins/keystone/views/credentials.lua",
    ["kong.plugins.keystone.views.auth_and_tokens"] = "kong/plugins/keystone/views/auth_and_tokens.lua"
  }
}
