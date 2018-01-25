local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")

local Credential = {}

local available_credential_types = {
    ec2 = true, cert = true
}

local function check_project(dao_factory, project_id)
    local temp, err = dao_factory.project:find({id = project_id})
    kutils.assert_dao_error(err, "projects:find")
    if not temp then
        return responses.send_HTTP_BAD_REQUEST("Invalid project ID")
    end

end

local function check_user(dao_factory, user_id)
    local temp, err = dao_factory.user:find({id = user_id})
    kutils.assert_dao_error(err, "user:find")
    if not temp then
        return responses.send_HTTP_BAD_REQUEST("Invalid user ID")
    end
end

local function check_type(type)
    if not available_credential_types[type] then
        return responses.send_HTTP_BAD_REQUEST("Invalid credential type")
    end
end

local function list_credentials(self, dao_factory)
    local args = {}
    if self.params.type then
        check_type(self.params.type)
        args.type = type
    end

    if self.params.user_id then
        check_user(dao_factory, self.params.user_id)
        args.user_id = self.params.user_id
    end

    local credentials, err
    if args.type or args.user_id then
        credentials, err = dao_factory.credential:find_all(args)
    else
        credentials, err = dao_factory.credential:find_all()
    end

    kutils.assert_dao_error(err, "credential:find_all")
    if not next(credentials) then
        return responses.send_HTTP_OK()
    end

    local resp = {
        links = {
            next = "null",
            previous = "null",
            self = self:build_url(self.req.parsed_url.path)
            },
            credentials = {}
    }

    for i = 1, #credentials do
        resp.credentials[i] = {}
        resp.credentials[i].id = credentials[i].id
        resp.credentials[i].user_id = credentials[i].user_id
        resp.credentials[i].project_id = credentials[i].project_id
        resp.credentials[i].blob = credentials[i].encrypted_blob --TODO: change it
        resp.credentials[i].type = credentials[i].type
        resp.credentials[i].links = {
                self = self:build_url(self.req.parsed_url.path)
            }
    end

    return responses.send_HTTP_OK(resp)
end

local function create_credential(self, dao_factory)
    local credential = self.params.credential
    if not credential then
        return responses.send_HTTP_BAD_REQUEST("Error: credential is nil, check self.params")
    end

    if not credential.project_id or not credential.type or not credential.blob or not credential.user_id then
        return responses.send_HTTP_BAD_REQUEST("Error: all params must present in the request")
    end

    check_project(dao_factory, credential.project_id)
    check_user(dao_factory, credential.user_id)
    check_type(credential.type)

    credential.id = utils.uuid()
    credential.links = {
                self = self:build_url(self.req.parsed_url.path)
            }

    local credential_obj = {id = credential.id, user_id = credential.user_id, project_id = credential.project_id, type = credential.type,
                        key_hash = 'fernet', encrypted_blob = credential.blob} --TODO: change key_hash and encrypted blob, use fernet

    local res, err = dao_factory.credential:insert(credential_obj) --TODO: check if unique?
    kutils.assert_dao_error(err, "credential:insert")

    return responses.send_HTTP_CREATED({credential = credential})
end

local function get_credential_info(self, dao_factory)
    local credential_id = self.params.credential_id
    if not credential_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad credential id")
    end

    local credential, err = dao_factory.credential:find({id = credential_id})
    kutils.assert_dao_error(err, "credential:find")

    if not credential then
         return responses.send_HTTP_BAD_REQUEST("Error: no such credential in the system")
    end

    credential.blob = credential.encrypted_blob --TODO: decrypt this with key_hash
    credential.encrypted_blob = nil
    credential.extra = nil
    credential.key_hash = nil
    credential.links = {
                self = self:build_url(self.req.parsed_url.path)
            }

    return responses.send_HTTP_OK({credential = credential})
end

local function update_credential(self, dao_factory)
    local credential_id = self.params.credential_id
    if not credential_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad credential id")
    end

    if not self.params.credential then
        return responses.send_HTTP_BAD_REQUEST("Error: self.params.credential is nil")
    end

    local credential, err = dao_factory.credential:find({id = credential_id})
    kutils.assert_dao_error(err, "credential:find")

    if not credential then
         return responses.send_HTTP_BAD_REQUEST("Error: no such credential in the system")
    end

    if self.params.credential.project_id then
        check_project(dao_factory, self.params.credential.project_id)
    end

    if self.params.credential.user_id then
        check_user(dao_factory, self.params.credential.user_id)
    end

    if self.params.credential.type then
        check_type(self.params.credential.type)
    end

    if self.params.credential.blob then
        self.params.credential.encrypted_blob = self.params.credential.blob --TODO: change it
        self.params.credential.blob = nil
    end

    local updated_credential, err = dao_factory.credential:update(self.params.credential, {id = credential_id})
    kutils.assert_dao_error(err, "credential:update")

    updated_credential.blob = updated_credential.encrypted_blob --TODO: decrypt this with key_hash
    updated_credential.encrypted_blob = nil
    updated_credential.extra = nil
    updated_credential.key_hash = nil
    updated_credential.links = {
                self = self:build_url(self.req.parsed_url.path)
            }
    return responses.send_HTTP_OK({credential = updated_credential})
end

local function delete_credential(self, dao_factory)
    local credential_id = self.params.credential_id
    if not credential_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad credential id")
    end

    local credential, err = dao_factory.credential:find({id = credential_id})
    kutils.assert_dao_error(err, "credential:find")

    if not credential then
         return responses.send_HTTP_BAD_REQUEST("Error: no such credential in the system")
    end

    local _, err = dao_factory.credential:delete({id = credential_id})
    kutils.assert_dao_error(err, "credential:delete")
    return responses.send_HTTP_NO_CONTENT()
end

Credential.list_credentials = list_credentials
Credential.create_credential = create_credential
Credential.get_credential_info = get_credential_info
Credential.update_credential = update_credential
Credential.delete_credential = delete_credential

local routes = {
    ["/v3/credentials"] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_credentials", dao_factory, self.params)
            Credential.list_credentials(self, dao_factory)
        end,
        POST = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_credential", dao_factory, self.params)
            Credential.create_credential(self, dao_factory)
        end
    },
    ["/v3/credentials/:credential_id"] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_credential", dao_factory, self.params)
            Credential.get_credential_info(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:update_credential", dao_factory, self.params)
            Credential.update_credential(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_credential", dao_factory, self.params)
            Credential.delete_credential(self, dao_factory)
        end
    }
}

return {routes = routes, credential = Credential}