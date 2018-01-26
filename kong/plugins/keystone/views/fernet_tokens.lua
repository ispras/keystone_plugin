local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local redis = require ("kong.plugins.keystone.redis")
local cjson = require "cjson"

local function validate_token(dao_factory, token_id, validate)
    responses.send_HTTP_BAD_REQUEST("Fernet Tokens can't be validated or revoked")
end

local function check_token(token, dao_factory, allow_expired, validate)
    -- token: { id }
    -- bool allow_expired:
    -- return token: { id, user_id }
    return token
end

local function generate_token(dao_factory, user, cached, scope_id)
    -- user: { id }
    -- bool cached
    -- return token: { id, expires, roles, issued_at }
    local token = {}
    return token
end

local function get_token_info(token_id)
    -- return token: { user_id, scope_id, roles, issued_at, is_admin }
    local token = {}
    return token
end

return {
    generate = generate_token,
    validate = validate_token,
    check = check_token,
    get_info = get_token_info
}