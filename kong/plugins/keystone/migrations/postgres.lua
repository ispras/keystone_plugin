return {
  {
    name = "2017-10-26-132500_keystone_initial_scheme",
    up = [[
      CREATE TABLE IF NOT EXISTS access_token(
        id varchar(64),
        access_secret varchar(64),
        authorizing_user_id varchar(64),
        project_id varchar(64),
        role_ids text,
        consumer_id varchar(64),
        expires_at varchar(64),
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.access_token_authorizing_user_idx')) IS NULL THEN
          CREATE INDEX access_token_authorizing_user_idx ON access_token(authorizing_user_id);
        END IF;
        IF (SELECT to_regclass('public.access_token_consumer_idx')) IS NULL THEN
          CREATE INDEX access_token_consumer_idx ON access_token(consumer_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS assignment(
        type varchar,
        actor_id varchar(64),
        target_id varchar(64),
        role_id varchar(64),
        inherited boolean,
        PRIMARY KEY (type, inherited, actor_id, target_id, role_id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.assignment_target_idx')) IS NULL THEN
          CREATE INDEX assignment_target_idx ON assignment(target_id);
        END IF;
        IF (SELECT to_regclass('public.assignment_role_idx')) IS NULL THEN
          CREATE INDEX assignment_role_idx ON assignment(role_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS config_register(
        type varchar(64),
        domain_id varchar(64),
        PRIMARY KEY (type)
      );

      CREATE TABLE IF NOT EXISTS consumer(
        id varchar(64),
        description varchar(64),
        secret varchar(64),
        extra text,
        PRIMARY KEY (id)
      );

      CREATE TABLE IF NOT EXISTS credential(
        id varchar(64),
        user_id varchar(64),
        project_id varchar(64),
        type varchar(255),
        extra text,
        key_hash varchar(64),
        encrypted_blob text,
        PRIMARY KEY (id)
      );

      CREATE TABLE IF NOT EXISTS endpoint(
        id varchar(64),
        legacy_endpoint_id varchar(64),
        interface varchar(8),
        service_id varchar(64),
        url text,
        extra text,
        enabled boolean,
        region_id varchar(255),
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.endpoint_service_idx')) IS NULL THEN
          CREATE INDEX endpoint_service_idx ON endpoint(service_id);
        END IF;
        IF (SELECT to_regclass('public.endpoint_region_idx')) IS NULL THEN
          CREATE INDEX endpoint_region_idx ON endpoint(region_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS endpoint_group(
        id varchar(64),
        name varchar(255),
        description text,
        filters text,
        PRIMARY KEY (id)
      );

      CREATE TABLE IF NOT EXISTS federated_user(
        id varchar(64),
        user_id varchar(64),
        idp_id varchar(64),
        protocol_id varchar(64),
        unique_id varchar(255),
        display_name varchar(255),
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.federated_user_user_idx')) IS NULL THEN
          CREATE INDEX federated_user_user_idx ON federated_user(user_id);
        END IF;
        IF (SELECT to_regclass('public.federated_user_idp_idx')) IS NULL THEN
          CREATE INDEX federated_user_idp_idx ON federated_user(idp_id);
        END IF;
        IF (SELECT to_regclass('public.federated_user_protocol_idx')) IS NULL THEN
          CREATE INDEX federated_user_protocol_idx ON federated_user(protocol_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS federation_protocol(
        id varchar(64),
        idp_id varchar(64),
        mapping_id varchar(64),
        PRIMARY KEY (id, idp_id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.federation_protocol_idp_idx')) IS NULL THEN
          CREATE INDEX federation_protocol_idp_idx ON federation_protocol(idp_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS group_(
        id varchar(64),
        domain_id varchar(64),
        name varchar(64),
        description text,
        extra text,
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.group__domain_idx')) IS NULL THEN
          CREATE INDEX group__domain_idx ON group_(domain_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS id_mapping(
        public_id varchar(64),
        domain_id varchar(64),
        local_id varchar(64),
        entity_type varchar,
        PRIMARY KEY (public_id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.id_mapping_domain_idx')) IS NULL THEN
          CREATE INDEX id_mapping_domain_idx ON id_mapping(domain_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS identity_provider(
        id varchar(64),
        enabled boolean,
        description text,
        domain_id varchar(64),
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.identity_provider_domain_idx')) IS NULL THEN
          CREATE INDEX identity_provider_domain_idx ON identity_provider(domain_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS idp_remote_ids(
        idp_id varchar(64),
        remote_id varchar(255),
        PRIMARY KEY (remote_id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.idp_remote_ids_idp_idx')) IS NULL THEN
          CREATE INDEX idp_remote_ids_idp_idx ON idp_remote_ids(idp_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS implied_role(
        prior_role_id varchar(64),
        implied_role_id varchar(64),
        PRIMARY KEY (prior_role_id, implied_role_id)
      );

      CREATE TABLE IF NOT EXISTS local_user(
        id varchar(64),
        user_id varchar(64) UNIQUE,
        domain_id varchar(64),
        name varchar(255),
        failed_auth_count int,
        failed_auth_at timestamp,
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.local_user_user_idx')) IS NULL THEN
          CREATE INDEX local_user_user_idx ON local_user(user_id);
        END IF;
        IF (SELECT to_regclass('public.local_user_domain_idx')) IS NULL THEN
          CREATE INDEX local_user_domain_idx ON local_user(domain_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS mapping(
        id varchar(64),
        rules text,
        PRIMARY KEY (id)
      );

      CREATE TABLE IF NOT EXISTS migrate_version(
        repository_id varchar(255),
        repository_path text,
        version int,
        PRIMARY KEY (repository_id)
      );

      CREATE TABLE IF NOT EXISTS nonlocal_user(
        domain_id varchar(64),
        name varchar(255),
        user_id varchar(64) UNIQUE,
        PRIMARY KEY (domain_id, name)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.nonlocal_user_user_idx')) IS NULL THEN
          CREATE INDEX nonlocal_user_user_idx ON nonlocal_user(user_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS password(
        id varchar(64),
        local_user_id varchar(64),
        password varchar(128),
        expires_at timestamp,
        self_service boolean,
        password_hash varchar(255),
        created_at timestamp,
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.password_local_user_idx')) IS NULL THEN
          CREATE INDEX password_local_user_idx ON password(local_user_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS policy(
        id varchar(64),
        type varchar(255),
        blob text,
        extra text,
        PRIMARY KEY (id)
      );

      CREATE TABLE IF NOT EXISTS policy_association(
        id varchar(64),
        policy_id varchar(64),
        endpoint_id varchar(64),
        service_id varchar(64),
        region_id varchar(64),
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.policy_association_endpoint_idx')) IS NULL THEN
          CREATE INDEX policy_association_endpoint_idx ON policy_association(endpoint_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS project(
        id varchar(64),
        name varchar(64),
        extra text,
        description text,
        enabled boolean,
        domain_id varchar(64),
        parent_id varchar(64),
        is_domain boolean,
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.project_domain_idx')) IS NULL THEN
          CREATE INDEX project_domain_idx ON project(domain_id);
        END IF;
        IF (SELECT to_regclass('public.project_parent_idx')) IS NULL THEN
          CREATE INDEX project_parent_idx ON project(parent_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS project_endpoint(
        endpoint_id varchar(64),
        project_id varchar(64),
        PRIMARY KEY (endpoint_id, project_id)
      );

      CREATE TABLE IF NOT EXISTS project_endpoint_group(
        endpoint_group_id varchar(64),
        project_id varchar(64),
        PRIMARY KEY (endpoint_group_id, project_id)
      );

      CREATE TABLE IF NOT EXISTS project_tag(
        project_id varchar(64),
        name varchar(255),
        PRIMARY KEY (project_id, name)
      );

      CREATE TABLE IF NOT EXISTS region(
        id varchar(255),
        description varchar(255),
        parent_region_id varchar(255),
        extra text,
        PRIMARY KEY (id)
      );

      CREATE TABLE IF NOT EXISTS request_token(
        id varchar(64),
        request_secret varchar(64),
        verifier varchar(64),
        authorizing_user_id varchar(64),
        requested_project_id varchar(64),
        role_ids text,
        consumer_id varchar(64),
        expires_at varchar(64),
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.request_token_consumer_idx')) IS NULL THEN
          CREATE INDEX request_token_consumer_idx ON request_token(consumer_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS revocation_event(
        id varchar(64),
        domain_id varchar(64),
        project_id varchar(64),
        user_id varchar(64),
        role_id varchar(64),
        trust_id varchar(64),
        consumer_id varchar(64),
        access_token_id varchar(64),
        issued_before timestamp,
        expires_at timestamp,
        revoked_at timestamp,
        audit_id varchar(64),
        audit_chain_id varchar(64),
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.revocation_event_project_idx')) IS NULL THEN
          CREATE INDEX revocation_event_project_idx ON revocation_event(project_id);
        END IF;
        IF (SELECT to_regclass('public.revocation_event_user_idx')) IS NULL THEN
          CREATE INDEX revocation_event_user_idx ON revocation_event(user_id);
        END IF;
        IF (SELECT to_regclass('public.revocation_event_issued_beforex')) IS NULL THEN
          CREATE INDEX revocation_event_issued_beforex ON revocation_event(issued_before);
        END IF;
        IF (SELECT to_regclass('public.revocation_event_revoked_atx')) IS NULL THEN
          CREATE INDEX revocation_event_revoked_atx ON revocation_event(revoked_at);
        END IF;
        IF (SELECT to_regclass('public.revocation_event_audit_idx')) IS NULL THEN
          CREATE INDEX revocation_event_audit_idx ON revocation_event(audit_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS role(
        id varchar(64),
        name varchar(255) UNIQUE,
        extra text,
        domain_id varchar(64),
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.role_namex')) IS NULL THEN
          CREATE INDEX role_namex ON role(name);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS sensitive_config(
        domain_id varchar(64),
        group_ varchar(255),
        option varchar(255),
        value text,
        PRIMARY KEY (domain_id, group_, option)
      );

      CREATE TABLE IF NOT EXISTS service(
        id varchar(64),
        type varchar(255),
        enabled boolean,
        name varchar(255),
        description text,
        PRIMARY KEY (id)
      );

      CREATE TABLE IF NOT EXISTS service_provider(
        auth_url varchar(255),
        id varchar(64),
        enabled boolean,
        description text,
        sp_url varchar(255),
        relay_state_prefix varchar(255),
        PRIMARY KEY (id)
      );

      CREATE TABLE IF NOT EXISTS token_(
        id varchar(64),
        expires timestamp,
        extra text,
        valid boolean,
        trust_id varchar(64),
        user_id varchar(64),
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.token__expiresx')) IS NULL THEN
          CREATE INDEX token__expiresx ON token_(expires);
        END IF;
        IF (SELECT to_regclass('public.token__trust_idx')) IS NULL THEN
          CREATE INDEX token__trust_idx ON token_(trust_id);
        END IF;
        IF (SELECT to_regclass('public.token__user_idx')) IS NULL THEN
          CREATE INDEX token__user_idx ON token_(user_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS trust(
        id varchar(64),
        trustor_user_id varchar(64),
        trustee_user_id varchar(64),
        project_id varchar(64),
        impersonation boolean,
        deleted_at timestamp,
        expires_at timestamp,
        remaining_uses int,
        allow_redelegation boolean,
        redelegated_trust_id varchar(64),
        redelegation_count int,
        extra text,
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.trust_trustor_user_idx')) IS NULL THEN
          CREATE INDEX trust_trustor_user_idx ON trust(trustor_user_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS trust_role(
        trust_id varchar(64),
        role_id varchar(64),
        PRIMARY KEY (trust_id, role_id)
      );

      CREATE TABLE IF NOT EXISTS user_(
        id varchar(64),
        extra text,
        enabled boolean,
        default_project_id varchar(64),
        created_at timestamp,
        last_active_at timestamp,
        domain_id varchar(64),
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('public.user__trustor_default_project_idx')) IS NULL THEN
          CREATE INDEX user__default_project_idx ON user_(default_project_id);
        END IF;
        IF (SELECT to_regclass('public.user__trustor_domain_idx')) IS NULL THEN
          CREATE INDEX user__domain_idx ON user_(domain_id);
        END IF;
      END$$;

      CREATE TABLE IF NOT EXISTS user_group_membership(
        user_id varchar(64),
        group_id varchar(64),
        PRIMARY KEY (user_id, group_id)
      );

      CREATE TABLE IF NOT EXISTS user_option(
        user_id varchar(64),
        option_id varchar(64),
        option_value text,
        PRIMARY KEY (user_id, option_id)
      );

      CREATE TABLE IF NOT EXISTS whitelisted_config(
        domain_id varchar(64),
        group_ varchar(64),
        option varchar(255),
        value text,
        PRIMARY KEY (domain_id, group_, option)
      );

    ]],
    down = [[
      DROP TABLE acess_token;
      DROP TABLE assignment;
      DROP TABLE config_register;
      DROP TABLE consumer;
      DROP TABLE credential;
      DROP TABLE endpoint;
      DROP TABLE enpoint_group;
      DROP TABLE federated_user;
      DROP TABLE federation_protocol;
      DROP TABLE group_;
      DROP TABLE id_mapping;
      DROP TABLE identity_provider;
      DROP TABLE idp_remote_ids;
      DROP TABLE implied_role;
      DROP TABLE local_user;
      DROP TABLE mapping;
      DROP TABLE migrate_version;
      DROP TABLE nonlocal_user;
      DROP TABLE password;
      DROP TABLE policy;
      DROP TABLE policy_association;
      DROP TABLE project;
      DROP TABLE project_endpoint;
      DROP TABLE project_endpoint_group;
      DROP TABLE project_tag;
      DROP TABLE region;
      DROP TABLE request_token;
      DROP TABLE revocation_event;
      DROP TABLE role;
      DROP TABLE sensitive_config;
      DROP TABLE service;
      DROP TABLE service_config;
      DROP TABLE token_;
      DROP TABLE trust;
      DROP TABLE trust_role;
      DROP TABLE user_;
      DROP TABLE user_group_membership;
      DROP TABLE user_option;
      DROP TABLE whitelisted_config;
      DROP TABLE cache;
    ]]
  }
}



