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
    eventlet_server = true,
}

local blocks = {
    trust = {
        enabled = true,
        allow_redelegation = true,
        max_redelegation_count = 3
    },
    default = {
        crypt_strength = 10000,
        public_endpoint = "None",
        admin_endpoint = "None",
        max_project_tree_depth = 5,
        max_param_size = 64,
        max_token_size = 255,
        member_role_id = "9fe2ff9ee4384b1894a90878d3e92bab",
        member_role_name = "_member_",
        list_limit = -1,
    },
    auth = {
        methods = {"external", "password", "token", "oauth2", "mapped"},
        password = "",

    },
    cors = {
        allowed_origin = {},
        allow_credentials = true,
        expose_headers = {"X-Auth-Token", "X-Openstack-Request-Id", "X-Subject-Token"},
        allow_methods = {"GET", "PUT", "POST", "DELETE", "PATCH"},
        allow_headers = {"X-Auth-Token", "X-Openstack-Request-Id", "X-Subject-Token", "X-Project-Id,X-Project-Name",
                            "X-Project-Domain-Id", "X-Project-Domain-Name,X-Domain-Id", "X-Domain-Name"},
    },
    eventlet_server = {
        public_port = 5000,

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
                    print("Block with name " .. block_name .. " is not presented in Keystone configuration")
                    cur_block = nil
                end
            elseif cur_block then
                local name_pos = line:find(" =")
                local value_pos = line:find("= ")
                if name_pos and value_pos then
                    local param_name = string.sub(line, 1, name_pos - 1)
                    local param_value = string.sub(line, value_pos + 2)
                    if param_name and param_value and blocks[cur_block][param_name] then -- checks if parameter with this name presents in current block
                        blocks[cur_block][param_name] = param_value
                    elseif param_name and param_value then
                        print("Parameter with name " .. param_name .. " is not presented in block with name " .. cur_block)
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

print(pl.dump(blocks))

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

print(pl.dump(get_response))

local keystone_id_pos = get_response[1]:find('"id"')
if keystone_id_pos then
    local keystone_id = get_response[1]:sub(keystone_id_pos + 6, keystone_id_pos + 41)
    http.request{
        url = url .. "/" .. keystone_id,
        method = "DELETE"
    }
end

local request_body = generate_req_body("name=keystone")
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


