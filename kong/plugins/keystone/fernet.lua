local M = {}

local struct = require "struct"
local os = require "os"
local urandom = require 'randbytes'
local methods_represent = {oauth1 = 1, password = 2, token = 3}

local function uuid_hex_to_bytes(uuid)
    return uuid -- TODO: need to convert uuid in bytes like uuid_obj.bytes in python
end

local function methods_to_int(methods)
    local result = 0
    for i = 1, #methods do
        result = result + methods_represent[methods[i]]
    end
    return result
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
local function create_token(version, user_id, methods, project_id, expiration_time, audit_ids)
    --Fernet Format Version (0x80) – the only version available – 8 bits
    --Current Timestamp – 64 bits:
    local current_time = struct.pack(">L", os.time())

    -- Initialization Vector (IV) – 128 bits
    local iv = urandom(16)


end


local UnscopedPayload = {}

UnscopedPayload.version = 0
UnscopedPayload.create_arguments_aply = function (kwargs)
    return True
end

UnscopedPayload.assemble = function (user_id, methods, project_id, domain_id, expires_at, --expires_at must be a number
                                    audit_ids, trust_id, federated_info, access_token_id)
    local b_user_id = uuid_hex_to_bytes(user_id)
    local int_methods = methods_to_int(methods)


end