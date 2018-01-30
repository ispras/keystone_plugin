local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local cjson = require "cjson"
local fernet = require ("resty.fernet")
local aes = require "resty.aes"
local hmac = require "resty.hmac"
local kfernet = require ("kong.plugins.keystone.fernet")
local redis = require ("kong.plugins.keystone.redis")

    local secret = 'MmcGs0_iRH-GybC41AcxdtgvgIi4kk3T94bAqoL7l-k='

local function touuid(str)
    str = str:gsub('.', function (c)
        return string.format('%02x', string.byte(c))
    end)
    local uuids = {}
    for i = 1, #str, 32 do
        uuids[#uuids + 1] = str(i, i+7)..'-'..str(i+8, i+11)..'-'..str(i+12, i+15)..'-'..str(i+16, i+19)..'-'..str(i+20, i+31)
    end
    return uuids
end
local function from_uuid_to_bytes(uuid)
    local format = '(..)(..)(..)(..)-(..)(..)-(..)(..)-(..)(..)-(..)(..)(..)(..)(..)(..)'
    local temp = {uuid:match(format) }
    local str = ''
    for _, v in ipairs(temp) do
        str = str..string.char(tonumber(v, 16))
    end
    return str
end

--local function encode_base64url(secret)
--    secret = ngx.encode_base64(secret)
--    secret = secret:gsub("+", "-"):gsub("/", "_")
--    return secret
--end

local function fernet_encode(raw_payload)
    local token_str = ngx.encode_base64(raw_payload)
    token_str = token_str:gsub("+", "-"):gsub("/", "_")
    token_str = ngx.escape_uri(token_str)
    return token_str
end
local function from_hex_to_bytes(hex_str)
    local len = string.len(hex_str)
    if len < 16 then
        hex_str = string.rep('0', 16-len)..hex_str
    end
    local byte_str = ''
    for i = 1, #hex_str, 2 do
        byte_str = byte_str..string.char(tonumber(hex_str(i, i+1), 16))
    end
    return byte_str
end
local function from_number_to_bytes(num)
    local hex_str = string.format('%02X', num)
    return from_hex_to_bytes(hex_str)
end

local function join_fernet(fernet_obj)
    -- fernet_obj: { ts, iv, payload, signed, sha256 }
    if not fernet_obj or not (fernet_obj.signed and fernet_obj.sha256) then
        error("invalid fernet object")
    end
    local raw_payload = fernet_obj.signed..fernet_obj.sha256
    local fernet_str = fernet_encode(raw_payload)
    return fernet_str
end

local function create_fernet_obj (secret, payload)
    local secret = fernet.decode_base64url(secret)
    local fernet_obj = {
        payload = from_hex_to_bytes(payload)
    }

    local secret_len = string.len(secret) / 2
    local sign_secret = secret(1, secret_len)
    local crypt_secret = secret(1 + secret_len, -1)

    fernet_obj.iv = from_uuid_to_bytes(utils.uuid())
--    fernet_obj.iv = from_hex_to_bytes('DE618783DD0F13AAE64BEE9A79862F74')
    local aes_128_cbc_with_iv = assert(aes:new(crypt_secret, nil, aes.cipher(128,"cbc"), {iv=fernet_obj.iv}))
    fernet_obj.payload = aes_128_cbc_with_iv:encrypt(fernet_obj.payload)

    fernet_obj.ts = os.time()
    local raw_ts = from_number_to_bytes(fernet_obj.ts)
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
    token.user_id = touuid(payload)[1]
    return token
end
function Token.generate(dao_factory, user, cached, scope_id)
    -- user: { id }
    -- bool cached
    -- return token: { id, expires, issued_at }
    local payload = '9602B01334F3ED7EB2483B91B8192BA043B58002B0423D45CDDEC84170BE365E0B31A1B15FCB41D5875002B443D991B07D6F4126D3664375957A5CBDD87B89BC'
    local fernet_obj = create_fernet_obj(secret, payload)
    local fernet_str = join_fernet(fernet_obj)
    if not fernet:verify(secret, fernet_str, 0).verified then
        error("failed to create verified token")
    end

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
    local user_id, scope_id -- TODO payload parse

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
        issued_at = fernet_obj.ts,
        roles = cache.roles,
        is_admin = cache.is_admin -- TODO relocate is_admin from token cache to roles cache
    }
    return token
end

return Token