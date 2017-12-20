local cjson = require ("cjson")

local parse_json = function(file_name)
    local file, err = io.open(file_name, "r")
    if not file or err then
        return nil, err
    end

    local t = file:read("*a")
    local storage = cjson.decode(t)

    file:close()

    return storage, nil
end

local function check_policy_rule(user, ident)
    if user.is_admin then
        return true
    end
    local pols = parse_json("/etc/kong/policy_example.json")
    local rule = 'identity:'..ident
    while rule and rule ~= '' do

    end


end

return {
    get = parse_json,
    check = check_policy_rule
}