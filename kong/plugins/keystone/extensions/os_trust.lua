local responses = require "kong.tools.responses"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")
local utils = require "kong.tools.utils"
local cjson = require "cjson"

local routes = {
    ['/v3/OS-TRUST/trusts'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_trusts", dao_factory, self.params)
            responses.send(list_trusts(self, dao_factory))
        end,
        POST = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_trust", dao_factory, self.params)
            responses.send(create_trust(self, dao_factory))
        end
    },
    ['/v3/OS-TRUST/trusts/:trust_id'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_trust", dao_factory, self.params)
            responses.send(get_trust(self, dao_factory))
        end,
        DELETE = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_trust", dao_factory, self.params)
            responses.send(delete_trust(self, dao_factory))
        end
    },
    ['/v3/OS-TRUST/trusts/:trust_id/roles/'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_delegated_roles", dao_factory, self.params)
            responses.send(list_delegated_roles(self, dao_factory))
        end,
    },
    ['/v3/OS-TRUST/trusts/:trust_id/roles/:role_id'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:get_delegated_role", dao_factory, self.params)
            responses.send(get_delegated_role(self, dao_factory))
        end,
        HEAD = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:check_role_delegated", dao_factory, self.params)
            responses.send(check_role_delegated(self, dao_factory))
        end
    },
}

return {
    routes = routes,
    auth = consuming_trust
}