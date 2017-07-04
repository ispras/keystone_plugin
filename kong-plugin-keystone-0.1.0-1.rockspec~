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
  "luasocket == 2.0.2",
  "penlight == 1.4.1",
  "mediator_lua == 1.1.2",
  "lua-resty-http == 0.08",
  "lua-resty-jit-uuid == 0.0.5",
  "multipart == 0.5",
  "version == 0.2",
  "lapis == 1.5.1",
  "lua-cassandra == 1.2.2",
  "pgmoon-mashape == 2.0.1",
  "luatz == 0.3",
  "lua_system_constants == 0.1.2",
  "lua-resty-iputils == 0.2.1",
  "luacrypto == 0.3.2",
  "luasyslog == 1.0.0",
  "lua_pack == 1.0.4",
  "lua-resty-dns-client == 0.4.2",
  "lua-resty-worker-events == 0.3.0",
  "luaposix >= 0.0"
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
    ["kong.plugins.keystone.uuid4"] = "kong/plugins/keystone/uuid4.lua"
  }
}
