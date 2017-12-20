local cjson = require ("cjson")
local kutils = require ("kong.plugins.keystone.utils")
local redis = require ("kong.plugins.keystone.redis")

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

local function get_role(rule)

    local pols = parse_json("/etc/kong/policy_example.json")
    local rule = rule
    while true do
        rule = rule:match('^%((.*)%)$') or rule
        if rule == "" or rule == "!" then
            return rule
        end
        local _, num = rule:gsub(' or ', '')
        if num > 0 then
            local format = "(.*) or (.*)"
            for i = 3, num do
                format = format.." or (.*)"
            end
            local temp = {rule:match(format) }
            if not next(temp) then return rule, true end
            rule = get_role(temp[1])
            for i = 2, #temp do
                rule = rule..' or '..get_role(temp[i])
            end
            return rule
        end
        local _, num = rule:gsub(' and ', '')
        if num > 0 then
            local format = "(.*) and (.*)"
            for i = 3, num do
                format = format.." and (.*)"
            end
            local temp = {rule:match(format)}
            if not next(temp) then return rule, true end
            rule = get_role(temp[1])
            for i = 2, #temp do
                rule = rule..' and '..get_role(temp[i])
            end
            return rule
        end

        local role = rule:match("role:(.*)")
        if role then
            return role
        end
        local temp = pols[rule] or pols[rule:match("rule:(.*)")]
        if not temp then
            return rule
        end
        rule = temp
    end
end

local function to_table(role)
    local _, num = role:gsub(' or ', '')
    local format = '(.*)'
    for i = 1, num do
        format = format..' or (.*)'
    end
    local roles = {role:match(format) }
    for k, role in ipairs(roles) do
        _, num = role:gsub(' and ', '')
        format = '(.*)'
        for i = 1, num do
            format = format..' and (.*)'
        end
        roles[k] = {role:match(format) }
        if not next(roles[k]) then return {role, format} end
    end
    return roles
end

local function check_valid(token_id)
    local red, err = redis.connect() -- TODO cache
    kutils.assert_dao_error(err, "redis connect")
    local temp, err = red:get(token_id)
    kutils.assert_dao_error(err, "redis get")
    if temp ~= ngx.null then
        if temp:match("^not_valid&") then
            return false
        end
        local user_id, scope_id = temp:match('(.*)&(.*)')
        temp, err = red:get(temp)
        kutils.assert_dao_error(err, "redis get")
        local roles = cjson.decode(temp).roles
        return true, user_id, roles
    end
    return false
end

local function check_policy_rule(user, rule, scope_id)
    if not user or not next(user) or not user.auth then
        return false, "Unauthorized"
    end
    if user.is_admin then
        return true
    end
    if not user.auth[scope_id] then
        return false, "Unauthorized"
    end
    local valid, user_id, roles = check_valid(user.auth[scope_id])
    if not valid then
        return false, "Unauthorized"
    end

    local role, err = get_role('identity:'..rule)
    if err then
        return false, "Unknown rule: "..role
    end

    if role == '' then
        return true
    elseif role == '!' then
        return false, "Forbidden"
    end

    local rules = to_table(role)
    for _, rules in ipairs(rules) do
        local check = true
        for _, rule in ipairs(rules) do
            local comp_user = rule:match("user_id:%%%((.*)%)s")
            local comp_proj = rule:match("project_id:%%%((.*)%)s")
            if comp_user then
                --TODO user_id on the left
            elseif comp_proj then
                --TODO project_id on the left
            elseif not kutils.has_id(roles, rule, "name") then
                check = false
                break
            end
        end
        if check then
            return true
        end
    end

    return false, "Forbidden"
end

return {
    get = parse_json,
    check = check_policy_rule,
    role = get_role,
    to_table = to_table
}