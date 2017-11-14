
local ACCESS_TOKEN_SCHEMA = {
    primary_key = {"id"},
    table = "access_token",
    fields = {
        id = { type = "string", required = true },
        access_secret = { type = "string", required = true },
        authorizing_user_id = { type = "string", required = true, queryable = true },
        project_id = { type = "string", required = true },
        role_ids = { type = "array", required = true },
        consumer_id = { type = "string", required = true, queryable = true },
        expires_at = { type = "string" },
    }
}

local ASSIGNMENT_SCHEMA = {
    primary_key = {"type", "actor_id", "target_id", "role_id", "inherited"},
    table = "assignment",
    fields = {
        type = { type = "string", enum = {"UserProject", "GroupProject", "GroupDomain"}, required = true },
        actor_id = { type = "string", required = true },
        target_id = { type = "string", required = true },
        role_id = { type = "string", required = true },
        inherited = { type = "boolean", required = true }
    }
}

local CONFIG_REGISTER_SCHEMA = {
    primary_key = {"type"},
    table = "config_register",
    fields = {
        type = { type = "string", required = true },
        domain_id = { type = "string", required = true }
    }
}

local CONSUMER_SCHEMA = {
    primary_key = {"id"},
    table = "consumer",
    fields = {
        id = { type = "string", required = true },
        description = { type = "string" },
        secret = { type = "string", required = true },
        extra = { type = "table" }
    }
}

local CREDENTIAL_SCHEMA = {
    primary_key = {"id"},
    table = "credential",
    fields = {
        id = { type = "string", required = true },
        user_id = { type = "string", required = true },
        project_id = { type = "string" },
        type = { type = "string", required = true },
        extra = { type = "table" },
        key_hash = { type = "string", required = true },
        encrypted_blob = { type = "string", required = true }
    }
}

local ENDPOINT_SCHEMA = {
    primary_key = {"id"},
    table = "endpoint",
    fields = {
        id = { type = "string", required = true },
        legacy_endpoint_id = { type = "string" },
        interface = { type = "string", required = true },
        service_id = { type = "string", required = true, queryable = true },
        url = { type = "url", required = true },
        extra = { type = "table" },
        enabled = { type = "boolean", required = true },
        region_id = { type = "string", queryable = true }
    }
}

local ENDPOINT_GROUP_SCHEMA = {
    primary_key = {"id"},
    table = "endpoint_group",
    fields = {
        id = { type = "string", required = true },
        name = { type = "string", required = true },
        description = { type = "string" },
        filters = { type = "array", required = true }
    }
}

local FEDERATED_USER_SCHEMA = {
    primary_key = {"id"},
    table = "federated_user",
    fields = {
        id = { type = "string", required = true },
        user_id = { type = "string", required = true, queryable = true },
        idp_id = { type = "string", required = true, queryable = true },
        protocol_id = { type = "string", required = true, queryable = true },
        unique_id = { type = "string", required = true },
        display_name = { type = "string" }
    }
}

local FEDERATION_PROTOCOL_SCHEMA = {
    primary_key = {"id", "idp_id"},
    table = "federation_protocol",
    fields = {
        id = { type = "string", required = true },
        idp_id = { type = "string", required = true },
        mapping_id = { type = "string", required = true }
    }
}

local GROUP_SCHEMA = {
    primary_key = {"id"},
    table = "group",
    fields = {
        id = { type = "string", required = true },
        domain_id = { type = "string", required = true, queryable = true },
        name = { type = "string", required = true },
        description = { type = "string" },
        extra = { type = "table" }
    }
}

local ID_MAPPING_SCHEMA = {
    primary_key = {"public_id"},
    table = "id_mapping",
    fields = {
        public_id = { type = "string", required = true },
        domain_id = { type = "string", required = true, queryable = true },
        local_id = { type = "string", required = true },
        entity_type = { type = "string", enum = {"user", "group"}, required = true }
    }
}

local IDENTITY_PROVIDER_SCHEMA = {
    primary_key = {"id"},
    table = "identity_provider",
    fields = {
        id = { type = "string", required = true },
        enabled = { type = "boolean", required = true },
        description = { type = "string" },
        domain_id = { type = "string", required = true, queryable = true }
    }
}

local IDP_REMOTE_IDS_SCHEMA = {
    primary_key = {"remote_id"},
    table = "idp_remote_ids",
    fields = {
        idp_id = { type = "string", queryable = true },
        remote_id = { type = "string", required = true }
    }
}

local IMPLIED_ROLE_SCHEMA = {
    primary_key = {"prior_role_id", "implied_role_id"},
    table = "implied_role",
    fields = {
        prior_role_id = { type = "string", required = true },
        implied_role_id = { type = "string", required = true }
    }
}

local LOCAL_USER_SCHEMA = {
    primary_key = {"id"},
    table = "local_user",
    fields = {
        id = { type = "string", required = true },
        user_id = { type = "string", required = true, unique = true, queryable = true },
        domain_id = { type = "string", required = true, queryable = true },
        name = { type = "string", required = true },
        failed_auth_count = { type = "number" },
        failed_auth_at = { type = "timestamp" }
    }
}

local MAPPING_SCHEMA = {
    primary_key = {"id"},
    table = "mapping",
    fields = {
        id = { type = "string", required = true },
        rules = { type = "string", required = true }
    }
}

local MIGRATE_VERSION_SCHEMA = {
    primary_key = {"repository_id"},
    table = "migrate_version",
    fields = {
        repository_id = { type = "string", required = true },
        repository_path = { type = "string" },
        version = { type = "number" }
    }
}

local NONLOCAL_USER_SCHEMA = {
    primary_key = {"domain_id", "name"},
    table = "nonlocal_user",
    fields = {
        domain_id = { type = "string", required = true },
        name = { type = "string", required = true },
        user_id = { type = "string", required = true, unique = true, queryable = true }
    }
}

local PASSWORD_SCHEMA = {
    primary_key = {"id"},
    table = "password",
    fields = {
        id = { type = "string", required = true },
        local_user_id = { type = "string", required = true, queryable = true },
        password = { type = "string" },
        expires_at = { type = "timestamp" },
        self_service = { type = "boolean" },
        password_hash = { type = "string" },
        created_at = { type = "timestamp", required = true }
    }
}

local POLICY_SCHEMA = {
    primary_key = {"id"},
    table = "policy",
    fields = {
        id = { type = "string", required = true },
        type = { type = "string", required = true },
        blob = { type = "string", required = true },
        extra = { type = "table" }
    }
}

local POLICY_ASSOCIATION_SCHEMA = {
    primary_key = {"id"},
    table = "policy_association",
    fields = {
        id = { type = "string", required = true },
        policy_id = { type = "string", required = true },
        endpoint_id = { type = "string", queryable = true },
        service_id = { type = "string" },
        region_id = { type = "string" }
    }
}

local PROJECT_SCHEMA = {
    primary_key = {"id"},
    table = "project",
    fields = {
        id = { type = "string", required = true },
        name = { type = "string", required = true },
        extra = { type = "table" },
        description = { type = "string" },
        enabled = { type = "boolean" },
        domain_id = { type = "string", queryable = true },
        parent_id = { type = "string", queryable = true },
        is_domain = { type = "boolean", required = true }
    }
}

local PROJECT_ENDPOINT_SCHEMA = {
    primary_key = {"endpoint_id", "project_id"},
    table = "project_endpoint",
    fields = {
        endpoint_id = { type = "string", required = true },
        project_id = { type = "string", required = true }
    }
}

local PROJECT_ENDPOINT_GROUP_SCHEMA = {
    primary_key = {"enpoint_group_id", "project_id"},
    table = "project_endpoint_group",
    fields = {
        endpoint_group_id = { type = "string", required = true },
        project_id = { type = "string", required = true }
    }
}

local PROJECT_TAG_SCHEMA = {
    primary_key = {"project_id", "name"},
    table = "project_tag",
    fields = {
        project_id = { type = "string", required = true },
        name = { type = "string", required = true }
    }
}

local REGION_SCHEMA = {
    primary_key = {"id"},
    table = "region",
    fields = {
        id = { type = "string", required = true },
        description = { type = "string", required = true },
        parent_region_id = { type = "string" },
        extra = { type = "table" }
    }
}

local REQUEST_TOKEN_SCHEMA = {
    primary_key = {"id"},
    table = "request_token",
    fields = {
        id = { type = "string", required = true },
        request_secret = { type = "string", required = true },
        verifier = { type = "string" },
        authorizing_user_id = { type = "string" },
        requested_project_id = { type = "string", required = true },
        role_ids = { type = "array" },
        consumer_id = { type = "string", required = true },
        expires_at = { type = "string" }
    }
}

local REVOCATION_EVENT_SCHEMA = {
    primary_key = {"id"},
    table = "revocation_event",
    fields = {
        id = { type = "string", required = true },
        domain_id = { type = "string" },
        project_id = { type = "string" },
        user_id = { type = "string" },
        role_id = { type = "string" },
        trust_id = { type = "string" },
        consumer_id = { type = "string" },
        access_token_id = { type = "string" },
        issued_before = { type = "timestamp", required = true },
        expires_at = { type = "timestamp" },
        revoked_at = { type = "timestamp", required = true },
        audit_id = { type = "string" },
        audit_chain_id = { type = "string" }
    }
}

local ROLE_SCHEMA = {
    primary_key = {"id"},
    table = "role",
    fields = {
        id = { type = "string", required = true },
        name = { type = "string", required = true },
        extra = { type = "table" },
        domain_id = { type = "string", required = true }
    }
}

local SENSITIVE_CONFIG_SCHEMA = {
    primary_key = {"domain_id", "group", "option"},
    table = "sensitive_config",
    fields = {
        domain_id = { type = "string", required = true },
        group = { type = "string", required = true },
        option = { type = "string", required = true },
        value = { type = "string", required = true }
    }
}

local SERVICE_SCHEMA = {
    primary_key = {"id"},
    table = "service",
    fields = {
        id = { type = "string", required = true },
        type = { type = "string" },
        enabled = { type = "boolean", required = true },
        name = { type = "string", required = true},
        description = { type = "string"}
    }
}

local SERVICE_PROVIDER_SCHEMA = {
    primary_key = {"id"},
    table = "service_provider",
    fields = {
        auth_url = { type = "url", required = true },
        id = { type = "string", required = true },
        enabled = { type = "boolean", required = true },
        description = { type = "string" },
        sp_url = { type = "url", required = true },
        relay_state_prefix = { type = "string", required = true }
    }
}

local TOKEN_SCHEMA = {
    primary_key = {"id"},
    table = "token_",
    fields = {
        id = { type = "string", required = true },
        expires = { type = "timestamp" },
        extra = { type = "string" },
        valid = { type = "boolean" },
        trust_id = { type = "string" },
        user_id = { type = "string" }
    }
}

local TRUST_SCHEMA = {
    primary_key = {"id"},
    table = "trust",
    fields = {
        id = { type = "string", required = true },
        trustor_user_id = { type = "string", required = true },
        trustee_user_id = { type = "string", required = true },
        project_id = { type = "string" },
        impersonation = { type = "boolean", required = true },
        deleted_at = { type = "timestamp" },
        expires_at = { type = "timestamp" },
        remaining_uses = { type = "number" },
        extra = { type = "table" }
    }
}

local TRUST_ROLE_SCHEMA = {
    primary_key = {"trust_id", "role_id"},
    table = "trust_role",
    fields = {
        trust_id = { type = "string", required = true },
        role_id = { type = "string", required = true }
    }
}

local USER_SCHEMA = {
    primary_key = {"id"},
    table = "user",
    fields = {
        id = { type = "string", required = true },
        extra = { type = "table" },
        enabled = { type = "boolean" },
        default_project_id = { type = "string" },
        created_at = { type = "timestamp" },
        last_active_at = { type = "timestamp" },
        domain_id = { type = "string", required = true }
    }
}

local USER_GROUP_MEMBERSHIP_SCHEMA = {
    primary_key = {"user_id", "group_id"},
    table = "user_group_membership",
    fields = {
        user_id = { type = "string", required = true },
        group_id = { type = "string", required = true }
    }
}

local USER_OPTION_SCHEMA = {
    primary_key = {"user_id", "option_id"},
    table = "user_option",
    fields = {
        user_id = { type = "string", required = true },
        option_id = { type = "string", required = true },
        option_value = { type = "string" }
    }
}

local WHITELISTED_CONFIG_SCHEMA = {
    primary_key = {"domain_id", "group", "option"},
    table = "whitelisted_config",
    fields = {
        domain_id = { type = "string", required = true },
        group = { type = "string", required = true },
        option = { type = "string", required = true },
        value = { type = "string", required = true }
    }
}

return {
    access_token = ACCESS_TOKEN_SCHEMA,
    assignment = ASSIGNMENT_SCHEMA,
    config_register = CONFIG_REGISTER_SCHEMA,
    consumer = CONSUMER_SCHEMA,
    credential = CREDENTIAL_SCHEMA,
    endpoint = ENDPOINT_SCHEMA,
    endpoint_group = ENDPOINT_GROUP_SCHEMA,
    federated_user = FEDERATED_USER_SCHEMA,
    federation_protocol = FEDERATION_PROTOCOL_SCHEMA,
    group = GROUP_SCHEMA,
    id_mapping = ID_MAPPING_SCHEMA,
    identity_provider = IDENTITY_PROVIDER_SCHEMA,
    idp_remote_ids = IDP_REMOTE_IDS_SCHEMA,
    implied_role = IMPLIED_ROLE_SCHEMA,
    local_user = LOCAL_USER_SCHEMA,
    mapping = MAPPING_SCHEMA,
    migrate_version = MIGRATE_VERSION_SCHEMA,
    nonlocal_user = NONLOCAL_USER_SCHEMA,
    password = PASSWORD_SCHEMA,
    policy = POLICY_SCHEMA,
    policy_association = POLICY_ASSOCIATION_SCHEMA,
    project = PROJECT_SCHEMA,
    project_endpoint = PROJECT_ENDPOINT_SCHEMA,
    project_endpoint_group = PROJECT_ENDPOINT_GROUP_SCHEMA,
    project_tag = PROJECT_TAG_SCHEMA,
    region = REGION_SCHEMA,
    request_token = REQUEST_TOKEN_SCHEMA,
    revocation_event = REVOCATION_EVENT_SCHEMA,
    role = ROLE_SCHEMA,
    sensitive_config = SENSITIVE_CONFIG_SCHEMA,
    service = SERVICE_SCHEMA,
    service_provider = SERVICE_PROVIDER_SCHEMA,
    token = TOKEN_SCHEMA,
    trust = TRUST_SCHEMA,
    trust_role = TRUST_ROLE_SCHEMA,
    user = USER_SCHEMA,
    user_group_membership = USER_GROUP_MEMBERSHIP_SCHEMA,
    user_option = USER_OPTION_SCHEMA,
    whitelisted_config = WHITELISTED_CONFIG_SCHEMA
}
