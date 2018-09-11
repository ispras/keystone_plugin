local responses = require "kong.tools.responses"
local kutils = require ("kong.plugins.keystone.utils")
local SERVER_IP = '127.0.0.1'

local version_v3 = {
    status = 'stable',
    updated = '2018-01-01T00:00:00Z',
    id = 'v3.4',
    ['media-types'] = {{
        base = 'application/json',
        type = 'application/vnd.openstack.identity-v3+json'
    }},
    links = {
        {href = '/v3/', rel = 'self'},
        {href = 'http://docs.openstack.org/', type = 'text/html', rel = 'describedby'}
    }
}

local version_v2 = {
    status = 'stable',
    updated = '2014-04-17T00:00:00Z',
    id = 'v2.0',
    ['media-types'] = {{
        base = 'application/json',
        type = 'application/vnd.openstack.identity-v2.0+json'
    }},
    links = {
        {href = "http://" .. SERVER_IP .. ':35357/v2.0/', rel = 'self'},
        {href = 'http://docs.openstack.org/', type = 'text/html', rel = 'describedby'}
    }
}

return {
    ["/v3"] = {
        GET = function(self, dao)
--            version_v3.links[1].href = self:build_url(version_v3.links[1].href)
--            responses.send_HTTP_OK({version = version_v3}, kutils.headers())
            local temp, err = dao.assignment:find_all({target_id = 'default'})
            kutils.assert_dao_error(err, "ass find all")
            responses.send_HTTP_OK(temp)
        end
    },
    ["/"] = {
        GET = function(self)
--            responses.send_HTTP_OK(self.req.headers)
            version_v3.links[1].href = self:build_url(version_v3.links[1].href)
            responses.send_HTTP_OK({ versions = { values = { version_v3, version_v2 } } }, kutils.headers())
        end
    }
}
