local responses = require "kong.tools.responses"
local errors = require "kong.dao.errors"
local uuid4 = require('uuid4')
local User = {}

local function get_headers()
	--local req_id = PREFIX .. COUNTER
    local headers = {}
    headers["x-openstack-request-id"] = uuid4.getUUID() -- uuid (uuid4)
    headers.Vary = "X-Auth-Token"
    return headers
end

local function list_users(self, dao_factory)
    local domain_id = self.req.domain_id
    local enabled = self.req.enabled
    local idp_id = self.req.idp_id
    local name = self.req.name
    local password_expires_at = self.req.password_expires_at
    local protocol_id = self.req.protocol_id
    local unique_id = self.req.unique_id

    local users, err = dao_factory.user:find_all()

    if err then
        responses.send(400, err)
    end
    responses.send_HTTP_OK(users, get_headers())
    return ''
end

local function create_user(self, dao_factory)
    return ''
end

local function get_user_info(self, dao_factory)
    local uid = self.params.user_id
    return ''
end

local function update_user(self, dao_factory)
    return ''
end

local function delete_user(self, dao_factory)
    return ''
end

local function list_user_groups(self, dao_factory)
    return ''
end

local function list_user_projects(self, dao_factory)
    return ''
end

local function change_user_password(self, dao_factory)
    return ''
end

User.list_users = list_users
User.create_user = create_user
User.get_user_info = get_user_info
User.update_user = update_user
User.delete_user = delete_user
User.list_user_groups = list_user_groups
User.list_user_projects = list_user_projects
User.change_user_password = change_user_password

return User