local responses = require "kong.tools.responses"
local cjson = require ("cjson")
--local kutils = require ("kong.plugins.keystone.utils")

local parse_json = function(file_name)
    local file, err = io.open(file_name, "r")
    if not file or err then
        responses.send_HTTP_CONFLICT(err)
    end

    local t = file:read("*a")
    local storage = cjson.decode(t)

    file:close()

    return storage
end

local function get_role(rule)
    --TODO http rule

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

local function handle_match(rule, user_id, scope_id, target, obj)
    local token_attr, api_call_attr = rule:match("(.*):%%%((.*)%)s")
    if not token_attr or not api_call_attr then
        return false
    end
    if token_attr == "user_id" then
        token_attr = user_id
    elseif token_attr == "project_id" or "domain_id" then
        token_attr = scope_id
    elseif token_attr == "None" then
        token_attr = null
    else
        responses.send_HTTP_CONFLICT("unknown attribute "..token_attr)
    end
    -- case: target.object.attribute
    local ob, at = api_call_attr:match("target.(.*)%.(.*)")
    if ob and at then
        local param = ob..'_id'
        local target_id = obj[param]
        if not target_id then
            return false
        end
        local temp, err = target[ob]:find({id = target_id})
        if err then
            return false
        end
        api_call_attr = temp[at]
    else
        -- case: object.attributes
        local _, num = api_call_attr:gsub("%.", '')
        local format = "(.*)"
        for i = 1, num do
            format = format.."%.(.*)"
        end
        local temp = { api_call_attr:match(format) }
        api_call_attr = obj
        for _, v in ipairs(temp) do
            if not api_call_attr then
                return false
            end
            api_call_attr = api_call_attr[v]
        end

    end
    if api_call_attr == token_attr then
        return true
    end
    return false
end

local function check_policy_rule(token, rule, target, obj)
    --TODO is_admin_project
    if not token then
        responses.send_HTTP_UNAUTHORIZED()
    end
    local kutils = require ("kong.plugins.keystone.utils")
    local Tokens = kutils.provider()
    local token = Tokens.get_info(token)
    if token.is_admin then
        return
    end

    local role = get_role(rule)

    if role == '' then
        return
    elseif role == '!' then
        responses.send_HTTP_FORBIDDEN()
    end

    local rules = to_table(role)
    for _, rules in ipairs(rules) do
        local check = false
        for _, rule in ipairs(rules) do

            if rule == '' then
                return
            elseif rule == '!' then
                responses.send_HTTP_FORBIDDEN()
            end

            -- attributes from token user_id, scope_id
            if handle_match(rule, token.user_id, token.scope_id, target, obj)
                    or kutils.has_id(token.roles, rule, "name") then
                check = true
                break
            end
        end
        if check then
            return
        end
    end

    responses.send_HTTP_FORBIDDEN()
end

return {
    get = parse_json,
    check = check_policy_rule,
    role = get_role,
    to_table = to_table
}