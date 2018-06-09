local responses = require "kong.tools.responses"
--local kutils = require ("kong.plugins.keystone.utils")
local http = require("socket.http")
local ltn12 = require("ltn12")
local pl = require ("pl.pretty")

local block_names = {
    trust = true,
    default = true,
    auth = true,
    cors = true,
    fernet_tokens = true,
    identity = true,
    matchmaker_redis = true,
    oslo_policy = true,
    resource = true,
    token = true,
}

local blocks = {
    default = {
        crypt_strength = 10000,
        public_endpoint = "",
        admin_endpoint = "",
        max_project_tree_depth = 5,
        max_param_size = 64,
        max_token_size = 255,
        member_role_id = "9fe2ff9ee4384b1894a90878d3e92bab",
        member_role_name = "member",
        list_limit = -1,
    },
    auth = {
        methods = 'external, password, token, oauth2, mapped',
        password = "",

    },
    cors = {
        allowed_origin = "",
        allow_credentials = "true",
        expose_headers = 'X-Auth-Token, X-Openstack-Request-Id, X-Subject-Token',
        allow_methods = 'GET, PUT, POST, DELETE, PATCH',
        allow_headers = [[X-Auth-Token, X-Openstack-Request-Id, X-Subject-Token, X-Project-Id, X-Project-Name,
                        X-Project-Domain-Id, X-Project-Domain-Name, X-Domain-Id, X-Domain-Name]],
    },
    fernet_tokens = {
        max_active_keys = 3
    },
    identity = {
        default_domain_id = "default",
        max_password_length = 4096,
    },
    matchmaker_redis = {
        host = "127.0.0.1",
        port = 6379,
        password = "",
        wait_timeout = 2000
    },

    oslo_policy = {
        policy_file = "policy.json",
        policy_default_rule = "default",
        policy_dirs = "policy.d"
    },
    resource = {
        admin_project_domain_name = "admin",
        admin_project_name = "admin",
        project_name_url_safe = "off",
        domain_name_url_safe = "off"
    },
    token = {
        expiration = 3600,
        provider = "fernet",
        revoke_by_id = "true",
        allow_rescope_scoped_token = "true",

    },
    trust = {
        enabled = "true",
        allow_redelegation = "true",
        max_redelegation_count = 3
    },

}

local function parse_config(keystone_path)
    local file = io.open(keystone_path, "r")
    if not file then
        print("Failed to open keystone configuration file with path " .. keystone_path)
        return false
    end

    local cur_block = nil
    for line in file:lines() do
        if not string.find(line, "^%s*#") then --checks if line is not a comment
            if string.find(line, "^[%[%]]") then -- checks if line is the name of block
                local block_name = string.sub(line, 2, line:find("]") - 1)
                block_name = block_name:lower()
                if block_names[block_name] then --block with this name presents in cofiguration
                    cur_block = block_name
                else
                    print("Block with name " .. block_name .. " is not used in Keystone configuration.")
                    cur_block = nil
                end
            elseif cur_block then
                local name_pos = line:find(" =")
                local value_pos = line:find("= ")
                if name_pos and value_pos then
                    local param_name = string.sub(line, 1, name_pos - 1)
                    local param_value = string.sub(line, value_pos + 2)
                    if param_name and param_value and blocks[cur_block][param_name] then -- checks if parameter with this name presents in current block
                        if param_value == "<None>" then
                            param_value = type(blocks[cur_block][param_name]) == "number" and -1 or ""
                        end
                        blocks[cur_block][param_name] = param_value
                    elseif param_name and param_value then
                        print("Parameter with name " .. param_name .. " is not used in block with name " .. cur_block .. ".")
                    end
                end
            end
        end
    end
    return true
end

local function generate_req_body(request_body)
    for block_k, block_v in pairs(blocks) do
       for k, v in pairs(block_v) do
           request_body = request_body .. "&config." .. block_k .. "_" .. k .. "=" .. v
       end
    end
    return request_body
end

local path = "/etc/kong/keystone.conf"
if not parse_config(path) then
    return
end

--print(pl.dump(blocks))

local get_req_body = "name=keystone"
local url = "http://localhost:8001/apis/mockbin/plugins"
local get_response = {}

http.request{
    url = url,
    sink = ltn12.sink.table(get_response),
    method = "GET",
    source = ltn12.source.string(get_req_body),
    headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["Content-Length"] = #get_req_body
    }
}

--print(pl.dump(get_response))

local keystone_id_pos = get_response[1]:find('"id"')
if keystone_id_pos then
    local keystone_id = get_response[1]:sub(keystone_id_pos + 6, keystone_id_pos + 41)
    http.request{
        url = url .. "/" .. keystone_id,
        method = "DELETE"
    }
end

local request_body = generate_req_body("name=keystone")

print()
http.request{
    url = url,
    sink = ltn12.sink.file(io.stdout),
    method = "POST",
    source = ltn12.source.string(request_body),
    headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["Content-Length"] = #request_body
    }
}


