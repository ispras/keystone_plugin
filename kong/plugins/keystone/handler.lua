local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.oauth2.access"

local KeystoneHandler = BasePlugin:extend()

function KeystoneHandler:new()
  KeystoneHandler.super.new(self, "keystone")
end

function KeystoneHandler:access(conf)
  KeystoneHandler.super.access(self)
  access.execute(conf)
end

return KeystoneHandler
