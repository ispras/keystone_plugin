local USER_SCHEMA = {
  primary_key = {"user_id"},
  table = "user_info",
  fields = {
    user_id = { type = "id" },
    tenant_id = { type = "id", required = true },
    user_name = { type = "string", required = true, unique = true },
    password = { type = "string", required = true },
    email = { type = "string", required = true },
    enabled = { type = "boolean", default = true },
    created_at = { type = "timestamp", immutable = true, dao_insert_value = true }
  }
}

local UNAME_TO_UID_SCHEMA = {
  primary_key = {"user_name"},
  table = "uname_to_uid",
  fields = {
    user_name = { type = "string" },
    user_id = { type = "id", required = true, unique = true }
  }
}

local TENNAME_TO_TENID_SCHEMA = {
  primary_key = {"tenant_name"},
  table = "tenname_to_tenid",
  fields = {
    tenant_name = { type = "string" },
    tenant_id = { type = "id", required = true, unique = true }
  }
}

local TENANT_SCHEMA = {
  primary_key = {"tenant_id"},
  table = "tenant_info",
  fields = {
    tenant_id = { type = "id", required = true }, 
    tenant_name = { type = "string", required = true, unique = true },
    description = { type = "string" },
    enabled = { type = "boolean", default = true }
  }
}

local TOKEN_SCHEMA = {
  primary_key = {"token_id"},
  table = "token_info",
  fields = {
    token_id = { type = "id"},
    user_id = { type = "id", required = true },
    tenant_id = { type = "id", required = true },
    issued_at = { type = "string", required = true },
    expires = { type = "string", required = true }
  }
}

return {
  user_info = USER_SCHEMA,
  tenant_info = TENANT_SCHEMA,
  token_info = TOKEN_SCHEMA,
  uname_to_uid = UNAME_TO_UID_SCHEMA,
  tenname_to_tenid = TENNAME_TO_TENID_SCHEMA
}

