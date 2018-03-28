local responses = require "kong.tools.responses"
--local kutils = require ("kong.plugins.keystone.utils")
local cjson = require "cjson"
local fernet = require ("resty.fernet")
local aes = require "resty.aes"
local hmac = require "resty.hmac"
local kfernet = require ("kong.plugins.keystone.fernet")
--local redis = require ("kong.plugins.keystone.redis")
local urandom = require 'randbytes'
local fkeys = require ("kong.plugins.keystone.views.fernet_keys")

local function join_fernet(fernet_obj)
    -- fernet_obj: { ts, iv, payload, signed, sha256 }
    if not fernet_obj or not (fernet_obj.signed and fernet_obj.sha256) then
        error("invalid fernet object")
    end
    local raw_payload = fernet_obj.signed..fernet_obj.sha256
    local fernet_str = kfernet.base64_encode(raw_payload)
    return fernet_str
end

local function create_fernet_obj (secret, payload)
    local secret = fernet.decode_base64url(secret)
    local fernet_obj = {
        payload = payload
    }

    local secret_len = string.len(secret) / 2
    local sign_secret = secret(1, secret_len)
    local crypt_secret = secret(1 + secret_len, -1)

    fernet_obj.iv = urandom(16)
    local aes_128_cbc_with_iv = assert(aes:new(crypt_secret, nil, aes.cipher(128,"cbc"), {iv=fernet_obj.iv}))
    fernet_obj.payload = aes_128_cbc_with_iv:encrypt(fernet_obj.payload)

    fernet_obj.ts = os.time()
    local raw_ts = kfernet.from_number_to_bytes(fernet_obj.ts)
    local version = string.char(0x80)
    fernet_obj.signed = version..raw_ts..fernet_obj.iv..fernet_obj.payload
    fernet_obj.sha256 = hmac:new(sign_secret, hmac.ALGOS.SHA256):final(fernet_obj.signed)

    return fernet_obj
end

local Token = {}

function Token.validate(dao_factory, token_id, validate)
    responses.send_HTTP_BAD_REQUEST("Fernet Tokens can't be validated or revoked")
end

function Token.check(token, dao_factory, allow_expired, validate)
    -- token: { id }
    -- bool allow_expired:
    -- return token: { id, user_id }
    local keys = fkeys.get()
    local fernet_obj
    for i = #keys, 0, -1 do
        fernet_obj = fernet:verify(keys[i], token.id, 0)
        if fernet_obj.verified then break end
    end
    if not fernet_obj.verified then
        responses.send_HTTP_BAD_REQUEST("Token is not verified")
    end
    local payload = kfernet.parse_payload(fernet_obj.payload)
    token.user_id = payload.user_id
    token.federated = payload.federated_info and true or false
    return token
end
function Token.generate(dao_factory, user, cached, scope_id, is_domain, trust_id)
    -- user: { id }
    -- bool cached
    -- return token: { id, expires, issued_at }
    local expires = os.time() + 24 * 60 * 60
    local info_obj = {
        user_id = user.id,
        project_id = not is_domain and scope_id or nil,
        domain_id = is_domain and scope_id or nil,
        expires_at = expires,
        methods = {},
        audit_ids = {}
    }
    if trust_id then
        info_obj.trust_id = trust_id
    end
    local payload = kfernet.create_payload(info_obj) -- byte view
    local secret = fkeys.get_primary()
    local fernet_obj = create_fernet_obj(secret, payload)
    local fernet_str = join_fernet(fernet_obj)
    if not fernet:verify(secret, fernet_str, 0).verified then
        error("failed to create verified token")
    end
--    responses.send_HTTP_BAD_REQUEST({fernet_obj = fernet_obj, fernet_str = fernet_str, secret = secret})

    local token = {
        id = fernet_str,
        expires = expires,
        issued_at = fernet_obj.ts
    }
    return token
end

function Token.get_info(token_id)
    -- return token: { user_id, scope_id, roles, issued_at, is_admin }
    local keys = fkeys.get()
    local fernet_obj
    for i = #keys, 0, -1 do
        fernet_obj = fernet:verify(keys[i], token_id, 0)
        if fernet_obj.verified then break end
    end
    if not fernet_obj.verified then
        responses.send_HTTP_BAD_REQUEST("Token is not verified")
    end
    local info_obj = kfernet.parse_payload(fernet_obj.payload)
    local user_id, scope_id = info_obj.user_id, info_obj.project_id or info_obj.domain_id

    local cache = {}
    if scope_id then
        local redis = require ("kong.plugins.keystone.redis")
        local red, err = redis.connect() -- TODO cache
        if err then error(err) end
        local temp, err = red:get(user_id..'&'..scope_id)
        if err then error(err) end
        if temp == ngx.null then
            responses.send_HTTP_CONFLICT("No scope info for token")
        end
        cache = cjson.decode(temp)
    end

    local token = {
        id = token_id,
        user_id = user_id,
        scope_id = scope_id,
        issued_at = fernet_obj.ts,
        roles = cache.roles,
        is_admin = cache.is_admin,
        expires = info_obj.expires_at
    }
    return token
end

return Token