local responses = require "kong.tools.responses"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")
local auth = require ("kong.plugins.keystone.views.auth_and_tokens").auth
local trust = require ("kong.plugins.keystone.extensions.os_trust").auth
local feder = require ("kong.plugins.keystone.extensions.os_federation").auth

local routes = {
    ["/v3/auth/tokens"] = {
        POST = function(self, dao_factory)
            if self.params.auth and self.params.auth.identity then
                if self.params.auth.identity.methods[1] == "token" then
                    if self.params.auth.scope and self.params.auth.scope['OS-TRUST:trust'] then
                        local Tokens = kutils.provider()
                        self.params.auth.identity.token = Tokens.check(self.params.auth.identity.token, dao_factory)
                        trust(self, dao_factory)
                    elseif self.params.auth.identity.token['OS-OAUTH2'] then
                        oauth2(self, dao_factory)
                    else
                        local Tokens = kutils.provider()
                        self.params.auth.identity.token = Tokens.check(self.params.auth.identity.token, dao_factory)
                        if self.params.auth.identity.token.federated then
                            feder(self, dao_factory)
                        else
                            auth.auth_token(self, dao_factory)
                        end
                    end
                elseif self.params.auth.identity.methods[1] == "password" then
                    auth.auth_password(self, dao_factory)
                else
                    responses.send_HTTP_BAD_REQUEST("Unknown authentication method")
                end
            else
                responses.send_HTTP_BAD_REQUEST()
            end
        end,
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:validate_and_show_token", dao_factory, self.params)
            auth.get_token_info(self, dao_factory)
        end,
        HEAD = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:check_token_head", dao_factory, self.params)
            auth.check_token(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:revoke_token", dao_factory, self.params)
            auth.revoke_token(self, dao_factory)
        end
    }
}

routes["/v2.0/auth/tokens"] = routes["/v3/auth/tokens"]

return routes