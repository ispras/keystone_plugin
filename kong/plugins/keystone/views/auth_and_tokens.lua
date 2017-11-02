AuthAndToken = {}

function auth_password_unscoped(self, dao_factory)
    return ''
end

function auth_password_scoped(self, dao_factory)
    return ''
end

function auth_password_explicit_unscoped(self, dao_factory)
    return ''
end

function auth_token_unscoped(self, dao_factory)
    return ''
end

function auth_token_scoped(self, dao_factory)
    return ''
end

function auth_token_explicit_unscoped(self, dao_factory)
    return ''
end

function get_token_info(self, dao_factory)
    return ''
end

function check_token(self, dao_factory)
    return ''
end

function revoke_token(self, dao_factory)
    return ''
end

function get_service_catalog(self, dao_factory)
    return ''
end

function get_project_scopes(self, dao_factory)
    return ''
end

function get_domain_scopes(self, dao_factory)
    return ''
end

AuthAndToken.auth_password_unscoped = auth_password_unscoped
AuthAndToken.auth_password_scoped = auth_password_scoped
AuthAndToken.auth_password_explicit_unscoped = auth_password_explicit_unscoped
AuthAndToken.auth_token_unscoped = auth_token_unscoped
AuthAndToken.auth_token_scoped = auth_token_scoped
AuthAndToken.auth_token_explicit_unscoped = auth_token_explicit_unscoped
AuthAndToken.get_token_info = get_token_info
AuthAndToken.check_token = check_token
AuthAndToken.revoke_token = revoke_token
AuthAndToken.get_service_catalog = get_service_catalog
AuthAndToken.get_project_scopes = get_project_scopes
AuthAndToken.get_domain_scopes = get_domain_scopes

return AuthAndToken