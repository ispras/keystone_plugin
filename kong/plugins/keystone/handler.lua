local BasePlugin = require "kong.plugins.base_plugin"
local KeystoneHandler = BasePlugin:extend()

function KeystoneHandler:new()
    KeystoneHandler.super.new(self, "keystone")
end

local function match_route(route)
    local routes = require "kong.plugins.keystone.routes"
    local args = {}
    for k, v in routes do
        if route:match(k) then
            local keys = {v:match(k)}
            local values = {route:match(k)}
            for i = 1, #keys do
                args[keys[i]:sub(2)] = values[i]
            end
            return v, args
        end
    end

end

function KeystoneHandler:access()
    local cjson = require "cjson"
    local api = require "kong.plugins.keystone.keystone_api"
    local dao = require "kong.singletons".dao
    ngx.req.read_body()
    local request = ngx.req.get_body_data()
    local uri_args = ngx.req.get_uri_args()
    self = {
        params = request and cjson.decode(request) or {},
        req = {
            headers = ngx.req.get_headers(),
            parsed_url = {
                path = ngx.var.request_uri,
                protocol = ngx.var.scheme,
                host = ngx.var.host,
                port = ngx.var.server_port
            }
        },
        build_url = function(obj, path)
            local url = obj.req.parsed_url.host..':'..obj.req.parsed_url.port..'/'..path
            url = url:gsub("%/%/", "%/")
            return obj.req.parsed_url.protocol..'://'..url
        end
    }
    for k, v in uri_args do
        self.params[k] = v
    end
    local route = ngx.var.uri
    if route:match("(.*)%/$") then -- TODO LENE NE NRAVITSYA
        route = route:sub(1, #route - 1)
    end
    if api[route] and api[route][ngx.req.get_method()] then
        api[route][ngx.req.get_method()](self, dao)
    else
        ngx.exit(404)
    end
end

return KeystoneHandler
