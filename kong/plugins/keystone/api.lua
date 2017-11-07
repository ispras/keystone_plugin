local views = {}
local users = require("views/users")
for k, v in pairs(users) do
    views[k] = v
end

return views