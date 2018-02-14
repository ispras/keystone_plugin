local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local redis = require ("kong.plugins.keystone.redis")
local cjson = require "cjson"

local function validate_token(dao_factory, token_id, validate)
    local kutils = require ("kong.plugins.keystone.utils")
    local redis = require ("kong.plugins.keystone.redis")
    local _, err = dao_factory.token:update({valid = validate}, {id = token_id})
    kutils.assert_dao_error(err, "token update")

    local red, err = redis.connect() -- TODO cache
    kutils.assert_dao_error(err, "redis connect")
    local temp, err = red:get(token_id)
    kutils.assert_dao_error(err, "redis get")
    if temp ~= ngx.null then
        if validate then
            temp = temp:match("^not_valid&(.*)")
            if not temp then kutils.assert_dao_error("error", "match") end
            local _, err = red:set(token_id, temp)
            kutils.assert_dao_error(err, "redis set")
        else
            local _, err = red:set(token_id, 'not_valid&'..temp)
            kutils.assert_dao_error(err, "redis set")
        end
    end
end

local function check_token(token, dao_factory, allow_expired, validate)
    local kutils = require ("kong.plugins.keystone.utils")
    if not token or not token.id then
        responses.send_HTTP_BAD_REQUEST("Token id is required")
    end

    local temp, err = dao_factory.token:find({id = token.id})
    kutils.assert_dao_error(err, "token:find")
    if not temp then
        responses.send_HTTP_BAD_REQUEST("No token found")
    end
    token = temp
    if not validate then
        if token.valid == false then
            responses.send_HTTP_BAD_REQUEST("Token is not valid")
        end
    elseif not token.valid then
        validate_token(dao_factory, token.id, true)
    end
    if not allow_expired then
        if token.expires and token.expires < os.time() then
            validate_token(dao_factory, token.id, false)
            responses.send_HTTP_BAD_REQUEST("Token is expired" )
        end
    elseif validate then
        if token.expires and token.expires < os.time() then
            token, err = dao_factory.token:update({expires = os.time() + 24*60*60}, {id = token.id})
            kutils.assert_dao_error(err, "token update")
        end
    end
    return token
end

local function generate_token(dao_factory, user, cached, scope_id)
    local kutils = require ("kong.plugins.keystone.utils")
    local redis = require ("kong.plugins.keystone.redis")
    local token = {
        id = utils.uuid(),
        valid = true,
        user_id = user.id,
        expires = os.time() + 24*60*60
    }
    local _, err = dao_factory.token:insert(token)
    kutils.assert_dao_error(err, "token:insert")

    if not cached then
        return token
    end

    local red, err = redis.connect() -- TODO cache
    kutils.assert_dao_error(err, "redis connect")
    local temp, err = red:get(user.id..'&'..scope_id)
    kutils.assert_dao_error(err, "redis get")
    token.issued_at = os.time()
    temp = cjson.decode(temp)
    temp.issued_at = token.issued_at
    local _, err = red:set(user.id..'&'..scope_id, cjson.encode(temp))
    kutils.assert_dao_error(err, "redis set")
    local _, err = red:set(token.id, user.id..'&'..scope_id)
    kutils.assert_dao_error(err, "redis set")

    return token
end

<<<<<<< HEAD
local function get_token_info(token_id)
    local kutils = require ("kong.plugins.keystone.utils")
    local redis = require ("kong.plugins.keystone.redis")
=======
local function get_token_info(token_id, dao_factory)
>>>>>>> b80a1ab6a6856cb62dc02e3939c13b4c3f2c8af8
    local red, err = redis.connect() -- TODO cache
    kutils.assert_dao_error(err, "redis connect")
    local key, err = red:get(token_id)
    kutils.assert_dao_error(err, "redis get")
    if key ~= ngx.null then
        if key:match("^not_valid&") then
            responses.send_HTTP_BAD_REQUEST("Invalid token")
        end
        local temp, err = red:get(key)
        kutils.assert_dao_error(err, "redis get")
        if temp == ngx.null then
            responses.send_HTTP_CONFLICT("No scope info for token")
        end
        local token = cjson.decode(temp)
        token.user_id, token.scope_id = key:match("(.*)&(.*)")
        token.issued_at = tonumber(token.issued_at)
        return token
    else
        local token, err = dao_factory.token:find({id = token_id})
        kutils.assert_dao_error(err, "token find")
        if not token then
            responses.send_HTTP_BAD_REQUEST("Authorization token is not found")
        end
        return token
    end
end

return {
    generate = generate_token,
    validate = validate_token,
    check = check_token,
    get_info = get_token_info
}