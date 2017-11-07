local views = {}
local users = require ('kong.plugins.keystone.views.users')
for k, v in pairs(users) do
    views[k] = v
end

return views