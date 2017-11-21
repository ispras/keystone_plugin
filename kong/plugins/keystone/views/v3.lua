local responses = require "kong.tools.responses"
local kutils = require ("kong.plugins.keystone.utils")
local json = require('cjson')
local SERVER_IP = '127.0.0.1'

local function v3()
    local body = {
            version = {
                status = 'stable',
                updated = '2014-04-17T00:00:00Z',
                id = 'v3',
                ['media-types'] = {{
                    base = 'application/json',
                    type = 'application/vnd.openstack.identity-v2.0+json'
                }},
                links = {
                    {href = "http://" .. SERVER_IP .. ':35357/v2.0/', rel = 'self'},
                    {href = 'http://docs.openstack.org/', type = 'text/html', rel = 'describedby'}
                }
        }
    }

	return responses.send_HTTP_OK(body, kutils.headers())
end

return {
    ["/v3"] = {
        GET = function(self, dao_factory)
            v3()
        end
    },
    ["/"] = {
        GET = function(self, dao_factory)
            body = json.decode('{ "versions":{ "values":[ { "status":"stable", "updated":"2015-03-30T00:00:00Z", "media-types":[ { "base":"application/json", "type":"application/vnd.openstack.identity-v3+json" } ], "id":"v3.4", "links":[ { "href":"https://localhost:8001/v3/", "rel":"self" } ] } ] } }')
            return responses.send_HTTP_OK(body, kutils.headers())
        end
    }
}
