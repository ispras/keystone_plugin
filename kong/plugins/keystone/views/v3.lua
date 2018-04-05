local responses = require "kong.tools.responses"
local kutils = require ("kong.plugins.keystone.utils")
local json = require('cjson')
local SERVER_IP = '127.0.0.1'
local projects = require ('kong.plugins.keystone.views.projects')
local roles = require ('kong.plugins.keystone.views.roles')
local users = require ('kong.plugins.keystone.views.users').User
local fkeys = require ("kong.plugins.keystone.views.fernet_keys")

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

local function init(self, dao_factory)
    local resp = {
        default_domain_id = '',
        admin_domain_id = '',
        admin_project_id = '',
        default_role_id = '',
        admin_role_id = '',
        admin_user_id = '',
    }

    self.params.project = {
        description = "The default domain",
        enabled = true,
        is_domain = true,
        name = "Default",
        id = 'default'
    }
    projects.create(self, dao_factory)
    local temp, err = dao_factory.project:find_all({name = "Default", is_domain = true})
    kutils.assert_dao_error(err, "project find all")
    resp.default_domain_id = temp[1].id

    self.params.project = {
        description = "Admin domain",
        enabled = true,
        is_domain = true,
        name = "admin"
    }
    projects.create(self, dao_factory)
    local temp, err = dao_factory.project:find_all({name = "admin", is_domain = true})
    kutils.assert_dao_error(err, "project find all")
    resp.admin_domain_id = temp[1].id

    self.params.project = {
        description = "Admin project",
        domain_id = resp.admin_domain_id,
        enabled = true,
        is_domain = false,
        name = "admin"
    }
    projects.create(self, dao_factory)
    local temp, err = dao_factory.project:find_all({name = "admin", is_domain = false, domain_id = resp.admin_domain_id})
    kutils.assert_dao_error(err, "project find all")
    resp.admin_project_id = temp[1].id

    self.params.role = {
        name = "member"
    }
    roles.create(self, dao_factory)
    local temp, err = dao_factory.role:find_all({name = "member"})
    kutils.assert_dao_error(err, "role find all")
    resp.default_role_id = temp[1].id

    self.params.role = {
        name = "admin"
    }
    roles.create(self, dao_factory)
    local temp, err = dao_factory.role:find_all({name = "admin"})
    kutils.assert_dao_error(err, "role find all")
    resp.admin_role_id = temp[1].id

    local file = io.open('/etc/kong/admin_creds', "r")
    if not file then
        responses.send_HTTP_BAD_REQUEST("Failed to open creds file")
    end
    local name = file:read()
    local password = file:read()
    file:close()
    if not name or not password then
        responses.send_HTTP_BAD_REQUEST("Failed to read creds")
    end

    self.params.user = {
        default_project_id = resp.admin_project_id,
        domain_id = resp.admin_domain_id,
        enabled = true,
        name = name,
        password = password
    }
    users.create_local(self, dao_factory)
    local temp, err = dao_factory.local_user:find_all({name = name, domain_id = resp.admin_domain_id})
    kutils.assert_dao_error(err, "local_user find all")
    resp.admin_user_id = temp[1].user_id

    self.params = {
        user_id = resp.admin_user_id,
        project_id = resp.admin_project_id,
        role_id = resp.admin_role_id
    }
    roles.assignment.assign(self, dao_factory, "UserProject", false, true)
    self.params = {
        user_id = resp.admin_user_id,
        domain_id = resp.admin_domain_id,
        role_id = resp.admin_role_id
    }
    roles.assignment.assign(self, dao_factory, "UserDomain", false, true)

    fkeys.rotate_keys()

    return resp
end

local function init2(self, dao_factory)
    local resp = {
        default_domain_id = '',
        admin_project_id = '',
        default_role_id = '',
        admin_role_id = '',
        admin_user_id = '',
    }

    self.params.project = {
        description = "The default domain",
        enabled = true,
        is_domain = true,
        name = "Default",
        id = 'default'
    }
    projects.create(self, dao_factory)
    local temp, err = dao_factory.project:find_all({name = "Default", is_domain = true})
    kutils.assert_dao_error(err, "project find all")
    resp.default_domain_id = temp[1].id

    self.params.project = {
        description = "Admin project",
        domain_id = resp.default_domain_id,
        enabled = true,
        is_domain = false,
        name = "admin"
    }
    projects.create(self, dao_factory)
    local temp, err = dao_factory.project:find_all({name = "admin", is_domain = false, domain_id = resp.default_domain_id})
    kutils.assert_dao_error(err, "project find all")
    resp.admin_project_id = temp[1].id

    self.params.role = {
        name = "member"
    }
    roles.create(self, dao_factory)
    local temp, err = dao_factory.role:find_all({name = "member"})
    kutils.assert_dao_error(err, "role find all")
    resp.default_role_id = temp[1].id

    self.params.role = {
        name = "admin"
    }
    roles.create(self, dao_factory)
    local temp, err = dao_factory.role:find_all({name = "admin"})
    kutils.assert_dao_error(err, "role find all")
    resp.admin_role_id = temp[1].id

    local file = io.open('/etc/kong/admin_creds', "r")
    if not file then
        responses.send_HTTP_BAD_REQUEST("Failed to open creds file")
    end
    local name = file:read()
    local password = file:read()
    file:close()
    if not name or not password then
        responses.send_HTTP_BAD_REQUEST("Failed to read creds")
    end

    self.params.user = {
        default_project_id = resp.admin_project_id,
        domain_id = resp.default_domain_id,
        enabled = true,
        name = name,
        password = password
    }
    users.create_local(self, dao_factory)
    local temp, err = dao_factory.local_user:find_all({name = name, domain_id = resp.default_domain_id})
    kutils.assert_dao_error(err, "local_user find all")
    resp.admin_user_id = temp[1].user_id

    self.params = {
        user_id = resp.admin_user_id,
        project_id = resp.admin_project_id,
        role_id = resp.admin_role_id
    }
    roles.assignment.assign(self, dao_factory, "UserProject", false, true)
    self.params = {
        user_id = resp.admin_user_id,
        domain_id = resp.default_domain_id,
        role_id = resp.admin_role_id
    }
    roles.assignment.assign(self, dao_factory, "UserDomain", false, true)

    fkeys.rotate_keys()

    return resp
end

--local function clear_redis()
--    local redis = require ("kong.plugins.keystone.redis")
--    local red, err = redis.connect() -- TODO cache
--    kutils.assert_dao_error(err, "redis connect")
--    red:flushall()
--    responses.send_HTTP_OK()
--end

return {
    ["/v3"] = {
        GET = function(self)
            version_v3.links[1].href = self:build_url(version_v3.links[1].href)
            responses.send_HTTP_OK({version = version_v3}, kutils.headers())
        end,
        POST = function(self, dao_factory)
            responses.send_HTTP_OK(init(self, dao_factory))
        end
    },
    ["/"] = {
        GET = function(self)
            version_v3.links[1].href = self:build_url(version_v3.links[1].href)
            responses.send_HTTP_OK({ versions = { values = { version_v3, version_v2 } } }, kutils.headers())
        end
    },
--    ['/clear_redis'] = {
--        GET = function ()
--            clear_redis()
--        end
--    }
}
