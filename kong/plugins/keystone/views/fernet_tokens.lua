local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local cjson = require "cjson"
local fernet = require ("resty.fernet")
local aes = require "resty.aes"
local hmac = require "resty.hmac"
local kfernet = require ("kong.plugins.keystone.fernet")
local redis = require ("kong.plugins.keystone.redis")
local urandom = require 'randbytes'


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

    local payload = fernet:verify(secret, token.id, 0).payload
    token.user_id = kfernet.parse_payload(payload).user_id
    return token
end
local function generate_key()
    local secret = urandom(32)
    secret = kfernet.base64_encode(secret)
    return secret
end

function Token.generate(dao_factory, user, cached, scope_id, is_domain)
    -- user: { id }
    -- bool cached
    -- return token: { id, expires, issued_at }
    local info_obj = {
        user_id = user.id,
        project_id = not is_domain and scope_id or nil,
        domain_id = is_domain and scope_id or nil,
        expires_at = 0
    }
    local payload = kfernet.create_payload(info_obj) -- byte view

    local secret = generate_key()
    local fernet_obj = create_fernet_obj(secret, payload)
    local fernet_str = join_fernet(fernet_obj)
    if not fernet:verify(secret, fernet_str, 0).verified then
        error("failed to create verified token")
    end
--    responses.send_HTTP_BAD_REQUEST({fernet_obj = fernet_obj, fernet_str = fernet_str, secret = secret})

    local token = {
        id = fernet_str,
        expires = nil,
        issued_at = fernet_obj.ts
    }
    return token
end

function Token.get_info(token_id)
    -- return token: { user_id, scope_id, roles, issued_at, is_admin }
    local fernet_obj = fernet:verify(secret, token_id, 0)
    local info_obj = kfernet.parse_payload(fernet_obj.payload)
    local user_id, scope_id = info_obj.user_id, info_obj.project_id or info_obj.domain_id

    local red, err = redis.connect() -- TODO cache
    kutils.assert_dao_error(err, "redis connect")
    local temp, err = red:get(user_id..scope_id)
    kutils.assert_dao_error(err, "redis get")
    if temp == ngx.null then
        responses.send_HTTP_CONFLICT("No scope info for token")
    end
    local cache = cjson.decode(temp).roles
    local token = {
        id = token_id,
        user_id = user_id,
        scope_id = scope_id,
        issued_at = fernet_obj.ts,
        roles = cache.roles,
        is_admin = cache.is_admin
    }
    return token
end

return Token