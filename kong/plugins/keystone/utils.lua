local utils = require "kong.tools.utils"
local fernet_tokens = require ("kong.plugins.keystone.views.fernet_tokens")
local uuid_tokens = require ("kong.plugins.keystone.views.uuid_tokens")

local function bool (a)
    if type(a) == "string" then
        return a == "true"
    else
        return a
    end
end
local default_domain = function(dao_factory)
    local domain, err = dao_factory.project:find_all({name = 'Default', is_domain = true})
    if not err and next(domain) then return domain[1]['id'] end
    return nil
end
local default_role = function(dao_factory)
    local role, err = dao_factory.role:find_all({name = 'member'})
    if not err and next(role) then return role[1]['id'] end
    return nil
end
local assert_dao_error = function(err, func)
    if err then
        if type(err) == "string" then
            error("error = "..err..", func = "..(func and func or ''))
        elseif err.message then
            error("error = "..err.message..", func = "..func)
        else
            local e = 'error = {'
            for k, v in pairs(err) do
                e = e.."\""..k.."\": \""..v.."\", "
            end
            e = e.."}, func = "..func
        end
    end
end
local time_to_string = function(timestamp)
    return timestamp and os.date("%Y-%m-%dT%X.000000Z", timestamp) or "null"
end
local string_to_time = function(s)
    if not s then return end
    local format ="(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d%d)"
    local time = {}
    local op
    op, time.year, time.month, time.day, time.hour, time.min, time.sec=s:match("(%a+):"..format)
    if not next(time) then
        time.year, time.month, time.day, time.hour, time.min, time.sec=s:match(format)
    end
    return os.time(time), op
end
local headers = function()
    local headers = {}
    headers["x-openstack-request-id"] = utils.uuid()
    headers.Vary = "X-Auth-Token"
    return headers
end
local has_id = function(array, id, field)
    if not array then
        return false
    end

    for i = 1, #array do
        if array[i] and (field and array[i][field] == id or array[i].id == id) then
            return i
        end
    end

    return false
end
local subtree = function (dao_factory, project_id, include_names)
    local subtree = {}
    local parent_id = project_id
    local a = 0
    while parent_id do
        local projects, err = dao_factory.project:find_all ({parent_id = parent_id})
        if err then
            return nil, err
        end
        for j = 1, #projects do
            local index = #subtree + 1
            subtree[index] = {
                id = projects[j].id,
                name = include_names and projects[j].name
            }
        end

        a = a + 1
        parent_id = subtree[a] and subtree[a].id
    end
    return subtree

end
local config_from_dao = function()
    local singletons = require "kong.singletons"
    local dao = singletons.dao
    local temp, err = dao.plugins:find_all({name='keystone'})
    assert_dao_error(err, "plugins find all")
    return temp[1].config
end

local function provider()
    local config = config_from_dao()
    if config.identity_provider == 'uuid' then
        return uuid_tokens
    elseif config.identity_provider == 'fernet' then
        return fernet_tokens
    end
end

return {
    bool = bool,
    default_domain = default_domain,
    default_role = default_role,
    assert_dao_error = assert_dao_error,
    time_to_string = time_to_string,
    string_to_time = string_to_time,
    headers = headers,
    has_id = has_id,
    subtree = subtree,
    config_from_dao = config_from_dao,
    provider = provider
}