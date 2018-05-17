local BasePlugin = require "kong.plugins.base_plugin"
--package.path = package.path .. ";/opt/zbstudio/lualibs/?/?.lua;/opt/zbstudio/lualibs/?.lua"
--package.cpath = package.cpath .. ";/opt/zbstudio/lualibs/bin/linux/x64/?.so;/opt/zbstudio/lualibs/bin/linux/x64/clibs/?.so"

local KeystoneHandler = BasePlugin:extend()

function KeystoneHandler:new()
    KeystoneHandler.super.new(self, "keystone")
end

return KeystoneHandler
