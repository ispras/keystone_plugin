local TRUST_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_trust",
    fields = {
        id = { type = "id" },
        trustor_user_id = { type = "id" },
        trustee_user_id = { type = "id" },
        project_id = { type = "id" },
        impersonation = { type = "boolean" },
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
        trust_id = { type = "id" },
        role_id = { type = "id" }
    }
}

local ID_MAPPING_SCHEMA = {
    primary_key = {"public_id"},
    table = "keystone_id_mapping",
    fields = {
        public_id = { type = "id" },
        domain_id = { type = "id" },
        local_id = { type = "id" },
        entity_type = { type = "string", enum = {"user", "group"} }
    }
}

local MAPPING_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_mapping",
    fields = {
        id = { type = "id" },
        rules = { type = "string" }
    }
}

local POLICY_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_policy",
    fields = {
        id = { type = "id" },
        type = { type = "string" },
        blob = { type = "string" },
        extra = { type = "table" }
    }
}

local POLICY_ASSOCIATION_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_policy_asssociation",
    fields = {
        id = { type = "id" },
        policy_id = { type = "id" },
        endpoint_id = { type = "id" },
        service_id = { type = "id" },
        region_id = { type = "id" }
    }
}

local ACCESS_TOKEN_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_access_token",
    fields = {
        id = { type = "id" },
        access_secret = { type = "string" },
        authorizing_user_id = { type = "id" },
        project_id = { type = "id" },
        role_ids = { type = "array" },
        consumer_id = { type = "id" },
        expires_at = { type = "timestamp" },
    }
}

local CONSUMER_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_consumer",
    fileds = {
        id = { type = "id" },
        description = { type = "string" },
        secret = { type = "string" },
        extra = { type = "table" }
    }
}

local IMPLIED_ROLE_SCHEMA = {
    primary_key = {"prior_role_id", "implied_role_id"},
    table = "keystone_implied_role",
    fileds = {
        prior_role_id = { type = "id" },
        implied_role_id = { type = "id" }
    }
}

local ROLE_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_role",
    fileds = {
        id = { type = "id" },
        name = { type = "string" },
        extra = { type = "table" },
        domain_id = { type = "id" }
    }
}

local ENDPOINT_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_endpoint",
    fields = {
        id = { type = "id" },
        legacy_endpoint_id = { type = "id" },
        interface = { type = "string" },
        service_id = { type = "id" },
        url = { type = "url" },
        extra = { type = "table" },
        enabled = { type = "boolean" },
        region_id = { type = "id" }
    }
}

local REGION_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_region",
    fields = {
        id = { type = "id" },
        description = { type = "string" },
        parent_region_id = { type = "id" },
        extra = { type = "table" }
    }
}

local SERVICE_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_service",
    fields = {
        id = { type = "id" },
        type = { type = "string" },
        enabled = { type = "boolean" },
        extra = { type = "table" }
    }
}

local SERVICE_PROVIDER_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_service_provider",
    fields = {
        auth_url = { type = "url" },
        id = { type = "id" },
        enabled = { type = "boolean" },
        description = { type = "string" },
        sp_url = { type = "url" },
        relay_state_prefix = { type = "string" }
    }
}

local FEDERATION_PROTOCOL_SCHEMA = {
    primary_key = {"id", "idp_id"},
    table = "keystone_federation_protocol",
    fields = {
        id = { type = "id" },
        idp_id = { type = "id" },
        mapping_id = { type = "id" }
    }
}
local IDENTITY_PROVIDER_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_identity_provider",
    fields = {
        id = { type = "id" },
        enabled = { type = "boolean" },
        description = { type = "string" },
        domain_id = { type = "id" }
    }
}

local IDP_REMOTE_IDS_SCHEMA = {
    primary_key = {"remote_id"},
    table = "keystone_idp_remote_ids",
    fileds = {
        idp_id = { type = "id" },
        remote_id = { type = "id" }
    }
}

local PROJECT_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_project",
    fileds = {
        id = { type = "id" },
        name = { type = "string" },
        extra = { type = "table" },
        description = { type = "string" },
        enabled = { type = "boolean" },
        domain_id = { type = "id" },
        parent_id = { type = "id" },
        is_domain = { type = "boolean" }
    }
}

local USER_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_user",
    fileds = {
        id = { type = "id" },
        extra = { type = "table" },
        enabled = { type = "boolean" },
        default_project_id = { type = "id" },
        created_at = { type = "timestamp" },
        last_active_at = { type = "timestamp" },
        domain_id = { type = "id" }
    }
}

local FEDERATED_USER_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_federated_user",
    fields = {
        id = { type = "id" },
        user_id = { type = "id" },
        idp_id = { type = "id" },
        protocol_id = { type = "id" },
        unique_id = { type = "id" },
        display_name = { type = "string" }
    }
}

local NONLOCAL_USER_SCHEMA = {
    primary_key = {"domain_id", "name"},
    table = "keystone_nonlocal_user",
    fields = {
        domain_id = { type = "id" },
        name = { type = "string" },
        user_id = { type = "id" }
    }
}

local PROJECT_ENDPOINT_SCHEMA = {
    primary_key = {"endpoint_id", "project_id"},
    table = "keystone_project_endpoint",
    fileds = {
        endpoint_id = { type = "id" },
        project_id = { type = "id" }
    }
}
local PROJECT_TAG_SCHEMA = {
    primary_key = {"project_id", "name"},
    table = "keystone_project_tag",
    fileds = {
        project_id = { type = "id" },
        name = { type = "string" }
    }
}

local PROJECT_ENDPOINT_GROUP_SCHEMA = {
    primary_key = {"enpoint_group_id", "project_id"},
    table = "keystone_project_endpoint_group",
    fileds = {
        endpoint_group_id = { type = "id" },
        project_id = { type = "id" }
    }
}

local MIGRATE_VERSION_SCHEMA = {
    primary_key = {"repository_id"},
    table = "keystone_migrate_version",
    fileds = {
        repository_id = { type = "id" },
        repository_path = { type = "string" },
        version = { type = "number" }
    }
}

local LOCAL_USER_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_local_user",
    fileds = {
        id = { type = "id" },
        user_id = { type = "id" },
        domain_id = { type = "id" },
        name = { type = "string" },
        failed_auth_count = { type = "number" },
        failed_auth_at = { type = "timestamp" }
    }
}

local CREDENTIAL_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_credential",
    fileds = {
        id = { type = "id" },
        user_id = { type = "id" },
        project_id = { type = "id" },
        type = { type = "string" },
        extra = { type = "table" },
        key_hash = { type = "string" },
        encrypted_blob = { type = "string" }
    }
}

local PASSWORD_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_password",
    fileds = {
        id = { type = "id" },
        local_user_id = { type = "id" },
        password = { type = "string" },
        expires_at = { type = "timestamp" },
        self_service = { type = "boolean" },
        password_hash = { type = "string" },
        created_at_int = { type = "number" },
        expires_at_int = { type = "number" },
        created_at = { type = "timestamp" }
    }
}

local TOKEN_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_token",
    fileds = {
        id = { type = "id" },
        expires = { type = "timestamp" },
        extra = { type = "table" },
        valid = { type = "boolean" },
        trust_id = { type = "id" },
        user_id = { type = "id" }
    }
}

local USER_OPTION_SCHEMA = {
    primary_key = {"user_id", "option_id"},
    table = "keystone_user_option",
    fileds = {
        user_id = { type = "id" },
        option_id = { type = "id" },
        option_value = { type = "string" }
    }
}

local USER_GROUP_MEMBERSHIP_SCHEMA = {
    primary_key = {"user_id", "group_id"},
    table = "keystone_user_group_membership",
    fileds = {
        user_id = { type = "id" },
        group_id = { type = "id" }
    }
}

local GROUP_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_group",
    fileds = {
        id = { type = "id" },
        domain_id = { type = "id" },
        name = { type = "string" },
        description = { type = "string" },
        extra = { type = "table" }
    }
}

local ENDPOINT_GROUP_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_endpoint_group",
    fields = {
        id = { type = "id" },
        name = { type = "string" },
        description = { type = "string" },
        filters = { type = "array" }
    }
}

local ASSIGNMENT_SCHEMA = {
    primary_key = {"type", "actor_id", "target_id", "role_id", "inherited"},
    table = "keystone_assignment",
    fileds = {
        type = { type = "string", enum = {"UserProject", "GroupProject", "GroupDomain"} },
        actor_id = { type = "id" },
        target_id = { type = "id" },
        role_id = { type = "id" },
        inherited = { type = "boolean" }
    }
}

local REQUEST_TOKEN_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_request_token",
    fileds = {
        id = { type = "id" },
        request_secret = { type = "string" },
        verifier = { type = "string" },
        authorizing_user_id = { type = "id" },
        requested_project_id = { type = "id" },
        role_ids = { type = "array" },
        consumer_id = { type = "id" },
        expires_at = { type = "timestamp" }
    }
}

local REVOCATION_EVENT_SCHEMA = {
    primary_key = {"id"},
    table = "keystone_revocation_event",
    fileds = {
        id = { type = "id" },
        domain_id = { type = "id" },
        project_id = { type = "id" },
        user_id = { type = "id" },
        role_id = { type = "id" },
        trust_id = { type = "id" },
        consumer_id = { type = "id" },
        access_token_id = { type = "id" },
        issued_before = { type = "timestamp" },
        expires_at = { type = "timestamp" },
        revoked_at = { type = "timestamp" },
        audit_id = { type = "id" },
        audit_chain_id = { type = "id" }
    }
}

local WHITELISTED_CONFIG_SCHEMA = {
    primary_key = {"domain_id", "group", "option"},
    table = "keystone_whitelisted_config",
    fileds = {
        domain_id = { type = "id" },
        group = { type = "string" },
        option = { type = "string" },
        value = { type = "string" }
    }
}

local SENSITIVE_CONFIG_SCHEMA = {
    primary_key = {"domain_id", "group", "option"},
    table = "keystone_sensetive_config",
    fileds = {
        domain_id = { type = "id" },
        group = { type = "id" },
        option = { type = "id" },
        value = { type = "id" }
    }
}

local CONFIG_REGISTER_SCHEMA = {
    primary_key = {"type"},
    table = "keystone_config_register",
    fields = {
        type = { type = "string" },
        domain_id = { type = "id" }
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
