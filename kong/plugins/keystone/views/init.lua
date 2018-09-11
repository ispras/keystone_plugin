local responses = require "kong.tools.responses"
local kutils = require ("kong.plugins.keystone.utils")
local json = require('cjson')
local projects = require ('kong.plugins.keystone.views.projects')
local roles = require ('kong.plugins.keystone.views.roles')
local users = require ('kong.plugins.keystone.views.users').User
local fkeys = require ("kong.plugins.keystone.views.fernet_keys")

local function init(self, dao_factory)
    local resp = {
        default_domain_id = '',
        admin_domain_id = '',
        admin_project_id_1 = '', -- from admin domain
        admin_project_id_2 = '', -- from default domain
        default_role_id = '',
        admin_role_id = '',
        admin_user_id_1 = '', -- from admin_domain
        admin_user_id_2 = '', -- from default domain
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

    local admin_domain_name = kutils.config_from_dao(self.config).resource_admin_project_domain_name or "admin"
    self.params.project = {
        description = "Admin domain",
        enabled = true,
        is_domain = true,
        name = admin_domain_name
    }
    projects.create(self, dao_factory)
    local temp, err = dao_factory.project:find_all({name = "admin", is_domain = true})
    kutils.assert_dao_error(err, "project find all")
    resp.admin_domain_id = temp[1].id

    local admin_project_name = kutils.config_from_dao(self.config).resource_admin_project_name or "admin"
    self.params.project = {
        description = "Admin project",
        domain_id = resp.admin_domain_id,
        enabled = true,
        is_domain = false,
        name = admin_project_name
    }
    projects.create(self, dao_factory)
    local temp, err = dao_factory.project:find_all({name = "admin", is_domain = false, domain_id = resp.admin_domain_id})
    kutils.assert_dao_error(err, "project find all")
    resp.admin_project_id_1 = temp[1].id

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
    resp.admin_project_id_2 = temp[1].id

    local member_role_name = kutils.config_from_dao(self.config).default_member_role_name or "member"
    self.params.role = {
        name = member_role_name
    }
    local default_role_id = kutils.config_from_dao(self.config).default_member_role_id or nil
    if default_role_id then
        self.params.role.id = default_role_id
    end

    roles.create(self, dao_factory)
    local temp, err = dao_factory.role:find_all({name = "member"})
    kutils.assert_dao_error(err, "role find all")
    resp.default_role_id = temp[1].id

    self.params.role = {
        name = "admin"
    }
    local temp, text = roles.create(self, dao_factory)
--    responses.send(temp, text)
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
        default_project_id = resp.admin_project_id_1,
        domain_id = resp.admin_domain_id,
        enabled = true,
        name = name,
        password = password
    }
    users.create_local(self, dao_factory)
    local temp, err = dao_factory.local_user:find_all({name = name, domain_id = resp.admin_domain_id})
    kutils.assert_dao_error(err, "local_user find all")
    resp.admin_user_id_1 = temp[1].user_id

    self.params.user = {
        default_project_id = resp.admin_project_id_2,
        domain_id = resp.default_domain_id,
        enabled = true,
        name = name,
        password = password
    }
    users.create_local(self, dao_factory)
    local temp, err = dao_factory.local_user:find_all({name = name, domain_id = resp.default_domain_id})
    kutils.assert_dao_error(err, "local_user find all")
    resp.admin_user_id_2 = temp[1].user_id

    self.params = {
        user_id = resp.admin_user_id_1,
        project_id = resp.admin_project_id_1,
        role_id = resp.admin_role_id
    }
    roles.assignment.assign(self, dao_factory, "UserProject", false, true)
    self.params = {
        user_id = resp.admin_user_id_1,
        domain_id = resp.admin_domain_id,
        role_id = resp.admin_role_id
    }
    roles.assignment.assign(self, dao_factory, "UserDomain", false, true)

    self.params = {
        user_id = resp.admin_user_id_2,
        project_id = resp.admin_project_id_2,
        role_id = resp.admin_role_id
    }
    roles.assignment.assign(self, dao_factory, "UserProject", false, true)
    self.params = {
        user_id = resp.admin_user_id_2,
        domain_id = resp.default_domain_id,
        role_id = resp.admin_role_id
    }
    roles.assignment.assign(self, dao_factory, "UserDomain", false, true)

    fkeys.rotate_keys(self.config)

    return resp
end

return {
    ["/v3"] = {
        POST = function(self, dao_factory)
            responses.send_HTTP_OK(init(self, dao_factory))
        end
    }
}