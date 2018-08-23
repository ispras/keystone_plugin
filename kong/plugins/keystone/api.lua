local views = {}

local function add_routes(obj)
    for k, v in pairs(obj) do
        views[k] = v
    end
end

local init = require("kong.plugins.keystone.views.init")
add_routes(init)

return views