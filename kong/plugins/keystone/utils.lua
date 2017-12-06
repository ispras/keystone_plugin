local utils = require "kong.tools.utils"

return {
    bool = function (a)
        if type(a) == "string" then
            return a == "true"
        else
            return a
        end
    end,
    default_domain = function(dao_factory)
        local domain, err = dao_factory.project:find_all({name = 'Default'})
        if not err and next(domain) then return domain[1]['id'] end
        return nil
    end,
    default_role = function(dao_factory)
        local role, err = dao_factory.role:find_all({name = 'Default'})
        if not err and next(role) then return role[1]['id'] end
        return nil
    end,
    assert_dao_error = function(err, func)
        if err then
            if type(err) == "string" then
                error("error = "..err..", func = "..func)
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
    end,
    time_to_string = function(timestamp)
        return timestamp and os.date("%Y-%m-%dT%X.000000Z", timestamp) or "null"
    end,
    string_to_time = function(s)
        local format ="(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+).(%d+)"
        local time = {}
        time.day, time.month, time.year, time.hour, time.min, time.sec, time.zone=s:match(format)
        return os.time(time)
    end,
    headers = function()
        local headers = {}
        headers["x-openstack-request-id"] = utils.uuid()
        headers.Vary = "X-Auth-Token"
        return headers
    end,
    parse_json = function(file_name)
        local storage = {}
        local file, err = io.open(file_name, "r")
        if not file or err then
            return err
        end

        while true do
            local t = file:read("*line")
            if not t then
                break
            end
            local a, b = t:match('\"(.*)\":%s\"(.*)\"')
            if a then
                storage[a] = b
            end

        end
        file:close()

        return nil, storage
    end,
    has_id = function(array, id, field)
        for i = 1, #array do
            if array[i] and (field and array[i][field] == id or array[i].id == id) then
                return i
            end
        end

        return false
    end,
    roles_to_string = function(roles)
        local s = ''
        for i,role in ipairs(roles) do
            if i ~= 1 then
                s = s..";"
            end
            s = s..role.id..","..role.name
        end

        return s
    end,
    string_to_roles = function(s)
        local roles = {}
        while s do
            local n = s:find(';')
            local role,b
            if n then
                role, b = s:sub(1, n-1), s:sub(n+1)
            else
                role = s
            end
            local i = #roles + 1
            roles[i] = {}
            roles[i].id, roles[i].name = role:match("(.*),(.*)")
            s = b
        end

        return roles
    end,
    subtree = function (dao_factory, project_id, include_names)
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
}
