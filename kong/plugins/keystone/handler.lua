local BasePlugin = require "kong.plugins.base_plugin"

local KeystoneHandler = BasePlugin:extend()

function KeystoneHandler:new()
    KeystoneHandler.super.new(self, "keystone")
end

return KeystoneHandler
