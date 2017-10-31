
local ACCESS_TOKEN_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_access_token",
    fields = {
        id = { type = "id", required = true },
        access_secret = { type = "string", required = true },
        authorizing_user_id = { type = "id", required = true, queryable = true },
        project_id = { type = "id", required = true },
        role_ids = { type = "array", required = true },
        consumer_id = { type = "id", required = true, queryable = true },
        expires_at = { type = "timestamp" },
    }
}

local ASSIGNMENT_SCHEMA = {
    primary_key = {"type", "actor_id", "target_id", "role_id", "inherited"},
    table = "keystone_assignment",
    fileds = {
        type = { type = "string", enum = {"UserProject", "GroupProject", "GroupDomain"}, required = true },
        actor_id = { type = "id", required = true },
        target_id = { type = "id", required = true },
        role_id = { type = "id", required = true },
        inherited = { type = "boolean", required = true }
    }
}

local CONFIG_REGISTER_SCHEMA = {
    primary_key = {"type"},
    table = "keystone_config_register",
    fields = {
        type = { type = "string", required = true },
        domain_id = { type = "id", required = true }
    }
}

local CONSUMER_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_consumer",
    fileds = {
        id = { type = "id", required = true },
        description = { type = "string" },
        secret = { type = "string", required = true },
        extra = { type = "table" }
    }
}

local CREDENTIAL_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_credential",
    fileds = {
        id = { type = "id", required = true },
        user_id = { type = "id", required = true },
        project_id = { type = "id" },
        type = { type = "string", required = true },
        extra = { type = "table" },
        key_hash = { type = "string", required = true },
        encrypted_blob = { type = "string", required = true }
    }
}

local ENDPOINT_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_endpoint",
    fields = {
        id = { type = "id", required = true },
        legacy_endpoint_id = { type = "id" },
        interface = { type = "string", required = true },
        service_id = { type = "id", required = true, queryable = true },
        url = { type = "url", required = true },
        extra = { type = "table" },
        enabled = { type = "boolean", required = true },
        region_id = { type = "id", queryable = true }
    }
}

local ENDPOINT_GROUP_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_endpoint_group",
    fields = {
        id = { type = "id", required = true },
        name = { type = "string", required = true },
        description = { type = "string" },
        filters = { type = "array", required = true }
    }
}

local FEDERATED_USER_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_federated_user",
    fields = {
        id = { type = "id", required = true },
        user_id = { type = "id", required = true, queryable = true },
        idp_id = { type = "id", required = true, queryable = true },
        protocol_id = { type = "id", required = true, queryable = true },
        unique_id = { type = "id", required = true },
        display_name = { type = "string" }
    }
}

local FEDERATION_PROTOCOL_SCHEMA = {
    primary_key = {"id", "idp_id"},
    table = "keystone_federation_protocol",
    fields = {
        id = { type = "id", required = true },
        idp_id = { type = "id", required = true },
        mapping_id = { type = "id", required = true }
    }
}

local GROUP_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_group",
    fileds = {
        id = { type = "id", required = true },
        domain_id = { type = "id", required = true, queryable = true },
        name = { type = "string", required = true },
        description = { type = "string" },
        extra = { type = "table" }
    }
}

local ID_MAPPING_SCHEMA = {
    primary_key = {"public_id"},
    table = "keystone_id_mapping",
    fields = {
        public_id = { type = "id", required = true },
        domain_id = { type = "id", required = true, queryable = true },
        local_id = { type = "id", required = true },
        entity_type = { type = "string", enum = {"user", "group"}, required = true }
    }
}

local IDENTITY_PROVIDER_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_identity_provider",
    fields = {
        id = { type = "id", required = true },
        enabled = { type = "boolean", required = true },
        description = { type = "string" },
        domain_id = { type = "id", required = true, queryable = true }
    }
}

local IDP_REMOTE_IDS_SCHEMA = {
    primary_key = {"remote_id"},
    table = "keystone_idp_remote_ids",
    fileds = {
        idp_id = { type = "id", queryable = true },
        remote_id = { type = "id", required = true }
    }
}

local IMPLIED_ROLE_SCHEMA = {
    primary_key = {"prior_role_id", "implied_role_id"},
    table = "keystone_implied_role",
    fileds = {
        prior_role_id = { type = "id", required = true },
        implied_role_id = { type = "id", required = true }
    }
}

local LOCAL_USER_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_local_user",
    fileds = {
        id = { type = "id", required = true },
        user_id = { type = "id", required = true, unique = true, queryable = true },
        domain_id = { type = "id", required = true, queryable = true },
        name = { type = "string", required = true },
        failed_auth_count = { type = "number" },
        failed_auth_at = { type = "timestamp" }
    }
}

local MAPPING_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_mapping",
    fields = {
        id = { type = "id", required = true },
        rules = { type = "string", required = true }
    }
}

local MIGRATE_VERSION_SCHEMA = {
    primary_key = {"repository_id"},
    table = "keystone_migrate_version",
    fileds = {
        repository_id = { type = "id", required = true },
        repository_path = { type = "string" },
        version = { type = "number" }
    }
}

local NONLOCAL_USER_SCHEMA = {
    primary_key = {"domain_id", "name"},
    table = "keystone_nonlocal_user",
    fields = {
        domain_id = { type = "id", required = true },
        name = { type = "string", required = true },
        user_id = { type = "id", required = true, unique = true, queryable = true }
    }
}

local PASSWORD_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_password",
    fileds = {
        id = { type = "id", required = true },
        local_user_id = { type = "id", required = true, queryable = true },
        password = { type = "string" },
        expires_at = { type = "timestamp" },
        self_service = { type = "boolean" },
        password_hash = { type = "string" },
        created_at_int = { type = "number", required = true },
        expires_at_int = { type = "number" },
        created_at = { type = "timestamp", required = true }
    }
}

local POLICY_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_policy",
    fields = {
        id = { type = "id", required = true },
        type = { type = "string", required = true },
        blob = { type = "string", required = true },
        extra = { type = "table" }
    }
}

local POLICY_ASSOCIATION_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_policy_asssociation",
    fields = {
        id = { type = "id", required = true },
        policy_id = { type = "id", required = true },
        endpoint_id = { type = "id", queryable = true },
        service_id = { type = "id" },
        region_id = { type = "id" }
    }
}

local PROJECT_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_project",
    fileds = {
        id = { type = "id", required = true },
        name = { type = "string", required = true },
        extra = { type = "table" },
        description = { type = "string" },
        enabled = { type = "boolean" },
        domain_id = { type = "id", required = true, queryable = true },
        parent_id = { type = "id", queryable = true },
        is_domain = { type = "boolean", required = true }
    }
}

local PROJECT_ENDPOINT_SCHEMA = {
    primary_key = {"endpoint_id", "project_id"},
    table = "keystone_project_endpoint",
    fileds = {
        endpoint_id = { type = "id", required = true },
        project_id = { type = "id", required = true }
    }
}

local PROJECT_ENDPOINT_GROUP_SCHEMA = {
    primary_key = {"enpoint_group_id", "project_id"},
    table = "keystone_project_endpoint_group",
    fileds = {
        endpoint_group_id = { type = "id", required = true },
        project_id = { type = "id", required = true }
    }
}

local PROJECT_TAG_SCHEMA = {
    primary_key = {"project_id", "name"},
    table = "keystone_project_tag",
    fileds = {
        project_id = { type = "id", required = true },
        name = { type = "string", required = true }
    }
}

local REGION_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_region",
    fields = {
        id = { type = "id", required = true },
        description = { type = "string", required = true },
        parent_region_id = { type = "id" },
        extra = { type = "table" }
    }
}

local REQUEST_TOKEN_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_request_token",
    fileds = {
        id = { type = "id", required = true },
        request_secret = { type = "string", required = true },
        verifier = { type = "string" },
        authorizing_user_id = { type = "id" },
        requested_project_id = { type = "id", required = true },
        role_ids = { type = "array" },
        consumer_id = { type = "id", required = true },
        expires_at = { type = "timestamp" }
    }
}

local REVOCATION_EVENT_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_revocation_event",
    fileds = {
        id = { type = "id", required = true },
        domain_id = { type = "id" },
        project_id = { type = "id" },
        user_id = { type = "id" },
        role_id = { type = "id" },
        trust_id = { type = "id" },
        consumer_id = { type = "id" },
        access_token_id = { type = "id" },
        issued_before = { type = "timestamp", required = true },
        expires_at = { type = "timestamp" },
        revoked_at = { type = "timestamp", required = true },
        audit_id = { type = "id" },
        audit_chain_id = { type = "id" }
    }
}

local ROLE_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_role",
    fileds = {
        id = { type = "id", required = true },
        name = { type = "string", required = true },
        extra = { type = "table" },
        domain_id = { type = "id", required = true }
    }
}

local SENSITIVE_CONFIG_SCHEMA = {
    primary_key = {"domain_id", "group", "option"},
    table = "keystone_sensetive_config",
    fileds = {
        domain_id = { type = "id", required = true },
        group = { type = "id", required = true },
        option = { type = "id", required = true },
        value = { type = "id", required = true }
    }
}

local SERVICE_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_service",
    fields = {
        id = { type = "id", required = true },
        type = { type = "string" },
        enabled = { type = "boolean", required = true },
        extra = { type = "table" }
    }
}

local SERVICE_PROVIDER_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_service_provider",
    fields = {
        auth_url = { type = "url", required = true },
        id = { type = "id", required = true },
        enabled = { type = "boolean", required = true },
        description = { type = "string" },
        sp_url = { type = "url", required = true },
        relay_state_prefix = { type = "string", required = true }
    }
}

local TOKEN_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_token",
    fileds = {
        id = { type = "id", required = true },
        expires = { type = "timestamp" },
        extra = { type = "table" },
        valid = { type = "boolean" },
        trust_id = { type = "id" },
        user_id = { type = "id" }
    }
}

local TRUST_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_trust",
    fields = {
        id = { type = "id", required = true },
        trustor_user_id = { type = "id", required = true },
        trustee_user_id = { type = "id", required = true },
        project_id = { type = "id" },
        impersonation = { type = "boolean", required = true },
        deleted_at = { type = "timestamp" },
        expires_at = { type = "timestamp" },
        remaining_uses = { type = "number" },
        extra = { type = "table" }
    }
}

local TRUST_ROLE_SCHEMA = {
    primary_key = {"trust_id", "role_id"},
    table = "keystone_trust_role",
    fields = {
        trust_id = { type = "id", required = true },
        role_id = { type = "id", required = true }
    }
}

local USER_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_user",
    fileds = {
        id = { type = "id", required = true },
        extra = { type = "table" },
        enabled = { type = "boolean" },
        default_project_id = { type = "id" },
        created_at = { type = "timestamp" },
        last_active_at = { type = "timestamp" },
        domain_id = { type = "id", required = true }
    }
}

local USER_GROUP_MEMBERSHIP_SCHEMA = {
    primary_key = {"user_id", "group_id"},
    table = "keystone_user_group_membership",
    fileds = {
        user_id = { type = "id", required = true },
        group_id = { type = "id", required = true }
    }
}

local USER_OPTION_SCHEMA = {
    primary_key = {"user_id", "option_id"},
    table = "keystone_user_option",
    fileds = {
        user_id = { type = "id", required = true },
        option_id = { type = "id", required = true },
        option_value = { type = "string" }
    }
}

local WHITELISTED_CONFIG_SCHEMA = {
    primary_key = {"domain_id", "group", "option"},
    table = "keystone_whitelisted_config",
    fileds = {
        domain_id = { type = "id", required = true },
        group = { type = "string", required = true },
        option = { type = "string", required = true },
        value = { type = "string", required = true }
    }
}

return {
    keystone_access_token = ACCESS_TOKEN_SCHEMA,
    keystone_assignment = ASSIGNMENT_SCHEMA,
    keystone_config_register = CONFIG_REGISTER_SCHEMA,
    keystone_consumer = CONSUMER_SCHEMA,
    keystone_credential = CREDENTIAL_SCHEMA,
    keystone_endpoint = ENDPOINT_SCHEMA,
    keystone_endpoint_group = ENDPOINT_GROUP_SCHEMA,
    keystone_federated_user = FEDERATED_USER_SCHEMA,
    keystone_federation_protocol = FEDERATION_PROTOCOL_SCHEMA,
    keystone_group = GROUP_SCHEMA,
    keystone_id_mapping = ID_MAPPING_SCHEMA,
    keystone_identity_provider = IDENTITY_PROVIDER_SCHEMA,
    keystone_idp_remote_ids = IDP_REMOTE_IDS_SCHEMA,
    keystone_implied_role = IMPLIED_ROLE_SCHEMA,
    keystone_local_user = LOCAL_USER_SCHEMA,
    keystone_mapping = MAPPING_SCHEMA,
    keystone_migrate_version = MIGRATE_VERSION_SCHEMA,
    keystone_nonlocal_user = NONLOCAL_USER_SCHEMA,
    keystone_password = PASSWORD_SCHEMA,
    keystone_policy = POLICY_SCHEMA,
    keystone_policy_asssociation = POLICY_ASSOCIATION_SCHEMA,
    keystone_project = PROJECT_SCHEMA,
    keystone_project_endpoint = PROJECT_ENDPOINT_SCHEMA,
    keystone_project_endpoint_group = PROJECT_ENDPOINT_GROUP_SCHEMA,
    keystone_project_tag = PROJECT_TAG_SCHEMA,
    keystone_region = REGION_SCHEMA,
    keystone_request_token = REQUEST_TOKEN_SCHEMA,
    keystone_revocation_event = REVOCATION_EVENT_SCHEMA,
    keystone_role = ROLE_SCHEMA,
    keystone_sensetive_config = SENSITIVE_CONFIG_SCHEMA,
    keystone_service = SERVICE_SCHEMA,
    keystone_service_provider = SERVICE_PROVIDER_SCHEMA,
    keystone_token = TOKEN_SCHEMA,
    keystone_trust = TRUST_SCHEMA,
    keystone_trust_role = TRUST_ROLE_SCHEMA,
    keystone_user = USER_SCHEMA,
    keystone_user_group_membership = USER_GROUP_MEMBERSHIP_SCHEMA,
    keystone_user_option = USER_OPTION_SCHEMA,
    keystone_whitelisted_config = WHITELISTED_CONFIG_SCHEMA
}
