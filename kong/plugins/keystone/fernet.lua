
local struct = require "struct"
local os = require "os"
local urandom = require 'randbytes'
local kutils = require ("kong.plugins.keystone.utils")
local msgpack = require "MessagePack"
local methods_represent = {oauth1 = 1, password = 2, token = 3}

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

local function methods_to_int(methods)
    local result = 0
    for i = 1, #methods do
        result = result + methods_represent[methods[i]]
    end
    return result
end

local function int_to_methods(int_methods)
    local methods = {}
    local j = 1
    for i = #methods_represent, 1 do
        if int_methods - i >= 0 then
            methods[j] = methods_represent[i]
            j = j + 1
        end
    end
    return methods
end

local function random_urlsafe_str_to_bytes(str)
    return ngx.decode_base64(str .. '==')
end

local function base64_encode(raw_payload)
    local token_str = ngx.encode_base64(raw_payload)
    token_str = token_str:gsub("+", "-"):gsub("/", "_")
    token_str = ngx.unescape_uri(token_str)
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


--Keystone fernet token is the base64 encoding of a collection of the following fields:
--Version: Fixed versioning by keystone:
--Unscoped Payload : 0
--Domain Scoped Payload : 1
--Project Scoped Payload : 2
--Trust Scoped Payload : 3
--Federated:
--Unscoped Payload : 4
--Domain Scoped Payload : 6
--Project Scoped Payload : 5

--User ID: Byte representation of User ID, uuid.UUID(user_id).bytes

--Methods: Integer representation of list of methods, a unique integer is assigned to each method,
-- for example, 1 to oauth1, 2 to password, 3 to token, etc. Now the sum of list of methods in the token generation
-- request is calculated, for example, for “methods”: [“password”], result is 2. For “methods”: [“password”, “token”],
-- result is 2 + 3 = 5.

--Project ID: Byte representation of Project ID, uuid.UUID(project_id).bytes

--Expiration Time: Timestamp integer of expiration time in UTC

--Audit IDs: Byte representation of URL-Safe string, restoring padding (==) at the end of the string


local UnscopedPayload = {}

UnscopedPayload.version = 0

UnscopedPayload.create_arguments_aply = function (kwargs)
    return True
end

UnscopedPayload.assemble = function (user_id, methods, project_id, domain_id, expires_at, --expires_at must be a number
                                    audit_ids, trust_id, federated_info, access_token_id)
    local b_user_id = from_uuid_to_bytes(user_id)
    local int_methods = methods_to_int(methods)
    local b_audit_ids = {}
    for i = 1, #audit_ids do
        b_audit_ids[i] = random_urlsafe_str_to_bytes(audit_ids[i])
    end

    return b_user_id, int_methods, expires_at, b_audit_ids
end

UnscopedPayload.disassemble = function (payload)
    local user_id = touuid(payload[1])[0]
    local methods = int_to_methods(payload[2])
    local expires_at_str = kutils.time_to_string(payload[3])
    local audit_ids = {}
    for i = 1, #payload[4] do
        audit_ids[i] = base64_encode(payload[4][i])
    end
    local project_id = nil
    local domain_id = nil
    local trust_id = nil
    local federated_info = nil
    local access_token_id = nil
    return user_id, methods, project_id, domain_id, expires_at_str, audit_ids, trust_id, federated_info, access_token_id
end

local DomainScopedPayload = {}

DomainScopedPayload.version = 1

DomainScopedPayload.create_arguments_aply = function (kwargs)
    return kwargs.domain_id
end

DomainScopedPayload.assemble = function (user_id, methods, project_id, domain_id, expires_at, --expires_at must be a number
                                    audit_ids, trust_id, federated_info, access_token_id)
    local b_user_id = from_uuid_to_bytes(user_id)
    local int_methods = methods_to_int(methods)
    local b_domain_id = from_uuid_to_bytes(domain_id)
    local b_audit_ids = {}
    for i = 1, #audit_ids do
        b_audit_ids[i] = random_urlsafe_str_to_bytes(audit_ids[i])
    end
    return b_user_id, int_methods, b_domain_id, expires_at, b_audit_ids
end

DomainScopedPayload.disassemble = function (payload)
    local user_id = touuid(payload[1])[0]
    local methods = int_to_methods(payload[2])
    local domain_id = touuid(payload[3])[0]
    local expires_at_str = kutils.time_to_string(payload[4])
    local audit_ids = {}
    for i = 1, #payload[5] do
        audit_ids[i] = base64_encode(payload[5][i])
    end
    local project_id = nil
    local trust_id = nil
    local federated_info = nil
    local access_token_id = nil
    return user_id, methods, project_id, domain_id, expires_at_str, audit_ids, trust_id, federated_info, access_token_id
end

local ProjectScopedPayload = {}

ProjectScopedPayload.version = 2

ProjectScopedPayload.create_arguments_aply = function (kwargs)
    return kwargs.project_id
end

ProjectScopedPayload.assemble = function (user_id, methods, project_id, domain_id, expires_at, --expires_at must be a number
                                    audit_ids, trust_id, federated_info, access_token_id)
    local b_user_id = from_uuid_to_bytes(user_id)
    local int_methods = methods_to_int(methods)
    local b_project_id = from_uuid_to_bytes(domain_id)
    local b_audit_ids = {}
    for i = 1, #audit_ids do
        b_audit_ids[i] = random_urlsafe_str_to_bytes(audit_ids[i])
    end
    return b_user_id, int_methods, b_project_id, expires_at, b_audit_ids
end

ProjectScopedPayload.disassemble = function (payload)
    local user_id = touuid(payload[1])[0]
    local methods = int_to_methods(payload[2])
    local project_id = touuid(payload[3])[0]
    local expires_at_str = kutils.time_to_string(payload[4])
    local audit_ids = {}
    for i = 1, #payload[5] do
        audit_ids[i] = base64_encode(payload[5][i])
    end
    local domain_id = nil
    local trust_id = nil
    local federated_info = nil
    local access_token_id = nil
    return user_id, methods, project_id, domain_id, expires_at_str, audit_ids, trust_id, federated_info, access_token_id
end

local TrustScopedPayload = {}

TrustScopedPayload.version = 3

TrustScopedPayload.create_arguments_aply = function (kwargs)
    return kwargs.trust_id
end

TrustScopedPayload.assemble = function (user_id, methods, project_id, domain_id, expires_at, --expires_at must be a number
                                    audit_ids, trust_id, federated_info, access_token_id)
    local b_user_id = from_uuid_to_bytes(user_id)
    local int_methods = methods_to_int(methods)
    local b_project_id = from_uuid_to_bytes(domain_id)
    local b_trust_id = from_uuid_to_bytes(trust_id)
    local b_audit_ids = {}
    for i = 1, #audit_ids do
        b_audit_ids[i] = random_urlsafe_str_to_bytes(audit_ids[i])
    end
    return b_user_id, int_methods, b_project_id, expires_at, b_audit_ids, b_trust_id
end

TrustScopedPayload.disassemble = function (payload)
    local user_id = touuid(payload[1])[0]
    local methods = int_to_methods(payload[2])
    local project_id = touuid(payload[3])[0]
    local expires_at_str = kutils.time_to_string(payload[4])
    local audit_ids = {}
    for i = 1, #payload[5] do
        audit_ids[i] = base64_encode(payload[5][i])
    end
    local trust_id = touuid(payload[6])[0]
    local domain_id = nil
    local federated_info = nil
    local access_token_id = nil
    return user_id, methods, project_id, domain_id, expires_at_str, audit_ids, trust_id, federated_info, access_token_id
end

local FederatedUnscopedPayload = {}

FederatedUnscopedPayload.version = 4

FederatedUnscopedPayload.create_arguments_aply = function (kwargs)
    return kwargs.federated_info
end

FederatedUnscopedPayload.assemble = function (user_id, methods, project_id, domain_id, expires_at, --expires_at must be a number
                                    audit_ids, trust_id, federated_info, access_token_id)
    local b_user_id = from_uuid_to_bytes(user_id)
    local int_methods = methods_to_int(methods)
    local b_group_ids = {}
    for i = 1, #federated_info.group_ids do
        b_group_ids[i] = from_uuid_to_bytes(federated_info.group_ids[i].id)
    end
    local b_idp_id = from_uuid_to_bytes(federated_info.idp_id)
    local protocol_id = federated_info.protocol_id
    local b_audit_ids = {}
    for i = 1, #audit_ids do
        b_audit_ids[i] = random_urlsafe_str_to_bytes(audit_ids[i])
    end
    return b_user_id, int_methods, b_group_ids, b_idp_id, protocol_id, expires_at, b_audit_ids
end

FederatedUnscopedPayload.disassemble = function (payload)
    local user_id = touuid(payload[1])[0]
    local methods = int_to_methods(payload[2])
    local group_ids = {}
    for i = 1, #payload[3] do
        group_ids[i] = touuid(payload[3][i])[0]
    end
    local idp_id = touuid(payload[4])[0]
    local protocol_id = payload[5]
    local expires_at_str = kutils.time_to_string(payload[6])
    local audit_ids = {}
    for i = 1, #payload[7] do
        audit_ids[i] = base64_encode(payload[7][i])
    end
    local federated_info = {group_ids = group_ids, idp_id = idp_id, protocol_id = protocol_id}
    local project_id = nil
    local trust_id = nil
    local domain_id = nil
    local access_token_id = nil
    return user_id, methods, project_id, domain_id, expires_at_str, audit_ids, trust_id, federated_info, access_token_id
end

local FederatedScopedPayload = {}

FederatedScopedPayload.version = nil

FederatedScopedPayload.assemble = function (user_id, methods, project_id, domain_id, expires_at, --expires_at must be a number
                                    audit_ids, trust_id, federated_info, access_token_id)
    local b_user_id = from_uuid_to_bytes(user_id)
    local int_methods = methods_to_int(methods)
    local b_scope_id = from_uuid_to_bytes(project_id or domain_id)
    local b_group_ids = {}
    for i = 1, #federated_info.group_ids do
        b_group_ids[i] = from_uuid_to_bytes(federated_info.group_ids[i].id)
    end
    local b_idp_id = from_uuid_to_bytes(federated_info.idp_id)
    local protocol_id = federated_info.protocol_id
    local b_audit_ids = {}
    for i = 1, #audit_ids do
        b_audit_ids[i] = random_urlsafe_str_to_bytes(audit_ids[i])
    end
    return b_user_id, int_methods, b_scope_id, b_group_ids, b_idp_id, protocol_id, expires_at, b_audit_ids
end

FederatedScopedPayload.disassemble = function (payload)
    local user_id = touuid(payload[1])[0]
    local methods = int_to_methods(payload[2])
    local scope_id = touuid(payload[3])[0]
    local project_id = nil
    local domain_id = nil
    if FederatedScopedPayload.version == FederatedProjectScopedPayload.version then
        project_id = scope_id
    elseif FederatedScopedPayload.version == FederatedDomainScopedPayload.version then
        domain_id = scope_id
    end
    local group_ids = {}
    for i = 1, #payload[4] do
        group_ids[i] = touuid(payload[4][i])[0]
    end
    local idp_id = touuid(payload[5])[0]
    local protocol_id = payload[6]
    local expires_at_str = kutils.time_to_string(payload[7])
    local audit_ids = {}
    for i = 1, #payload[8] do
        audit_ids[i] = base64_encode(payload[8][i])
    end
    local federated_info = {group_ids = group_ids, idp_id = idp_id, protocol_id = protocol_id}
    local trust_id = nil
    local access_token_id = nil
    return user_id, methods, project_id, domain_id, expires_at_str, audit_ids, trust_id, federated_info, access_token_id
end

local FederatedProjectScopedPayload = {}

FederatedProjectScopedPayload.version = 5
FederatedProjectScopedPayload.create_arguments_aply = function (kwargs)
    FederatedScopedPayload.version = FederatedProjectScopedPayload.version
    return kwargs.project_id and kwargs.federated_info
end

FederatedProjectScopedPayload.assemble = FederatedScopedPayload.assemble
FederatedProjectScopedPayload.disassemble = FederatedScopedPayload.disassemble

local FederatedDomainScopedPayload = {}

FederatedDomainScopedPayload.version = 6
FederatedDomainScopedPayload.create_arguments_aply = function (kwargs)
    FederatedScopedPayload.version = FederatedDomainScopedPayload.version
    return kwargs.domain_id and kwargs.federated_info
end

FederatedDomainScopedPayload.assemble = FederatedScopedPayload.assemble
FederatedDomainScopedPayload.disassemble = FederatedScopedPayload.disassemble

local OauthScopedPayload = {}

OauthScopedPayload.version = 7

OauthScopedPayload.create_arguments_aply = function (kwargs)
    return kwargs.access_token_id
end

OauthScopedPayload.assemble = function (user_id, methods, project_id, domain_id, expires_at, --expires_at must be a number
                                    audit_ids, trust_id, federated_info, access_token_id)
    local b_user_id = from_uuid_to_bytes(user_id)
    local int_methods = methods_to_int(methods)
    local b_project_id = from_uuid_to_bytes(project_id)
    local b_audit_ids = {}
    for i = 1, #audit_ids do
        b_audit_ids[i] = random_urlsafe_str_to_bytes(audit_ids[i])
    end
    local b_access_token_id = from_uuid_to_bytes(access_token_id)
    return b_user_id, int_methods, b_project_id, b_access_token_id, expires_at, b_audit_ids
end

OauthScopedPayload.disassemble = function (payload)
    local user_id = touuid(payload[1])[0]
    local methods = int_to_methods(payload[2])
    local project_id = touuid(payload[3])[0]
    local access_token_id = touuid(payload[4])[0]
    local expires_at_str = kutils.time_to_string(payload[5])
    local audit_ids = {}
    for i = 1, #payload[6] do
        audit_ids[i] = base64_encode(payload[6][i])
    end
    local federated_info = nil
    local trust_id = nil
    local domain_id = nil
    return user_id, methods, project_id, domain_id, expires_at_str, audit_ids, trust_id, federated_info, access_token_id
end

local PayloadClasses = {
    OauthScopedPayload,
    TrustScopedPayload,
    FederatedProjectScopedPayload,
    FederatedDomainScopedPayload,
    FederatedUnscopedPayload,
    ProjectScopedPayload,
    DomainScopedPayload,
    UnscopedPayload
}

local function create_payload(info_obj) --user_id, expires_at, audit_ids, methods=None, domain_id=None, project_id=None, trust_id=None, federated_info=None, access_token_id=None
    local payload
    for i = 1, #PayloadClasses do
        if PayloadClasses[i].create_arguments_aply(info_obj.user_id, info_obj.methods, info_obj.project_id,
                                                    info_obj.domain_id, info_obj.expires_at, info_obj.audit_ids, info_obj.trust_id,
                                                        info_obj.federated_info, info_obj.access_token_id) then  
            payload = {PayloadClasses[i].version, PayloadClasses[i].assemmble(info_obj)}
            break
        end
    end

    return msgpack.pack(payload)
end

local function parse_payload(payload)
    payload = msgpack.unpack(payload)
    local version = payload[1]
    local not_versioned_payload = {}
    for i = 1, #payload - 1 do
        not_versioned_payload[i] = payload[i + 1]
    end
    local info_obj
    for i = 1, #PayloadClasses do
        if PayloadClasses[i].version == version then
            info_obj = PayloadClasses[i].disassemble(not_versioned_payload)
            break
        end
    end
    return info_obj
end

return {
    create_payload = create_payload,
    parse_payload = parse_payload,
    touuid = touuid,
    from_uuid_to_bytes = from_uuid_to_bytes,
    base64_encode = base64_encode,
    from_hex_to_bytes = from_hex_to_bytes,
    from_number_to_bytes = from_number_to_bytes
}