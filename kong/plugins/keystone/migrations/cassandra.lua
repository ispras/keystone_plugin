return {
  {
    name = "2017-10-26-132500_keystone_initial_scheme",
    up = [[
    

      CREATE TABLE IF NOT EXISTS access_token(
        id varchar,
        access_secret varchar,
        authorizing_user_id varchar,
        project_id varchar,
        role_ids text,
        consumer_id varchar,
        expires_at timestamp,
        PRIMARY KEY (id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON access_token(authorizing_user_id);
      CREATE INDEX IF NOT EXISTS ON access_token(consumer_id);

      CREATE TABLE IF NOT EXISTS assignment(
        type varchar,
        actor_id varchar,
        target_id varchar,
        role_id varchar,
        inherited boolean,
        PRIMARY KEY (type, inherited, actor_id, target_id, role_id)
      );

      CREATE INDEX IF NOT EXISTS ON assignment(target_id);
      CREATE INDEX IF NOT EXISTS ON assignment(role_id);

      CREATE TABLE IF NOT EXISTS config_register(
        type varchar,
        domain_id varchar,
        PRIMARY KEY (type)
      );

      CREATE TABLE IF NOT EXISTS consumer(
        id varchar,
        description varchar,
        secret varchar,
        extra text,
        auth_url text,
        token_url text,
        userinfo_url text,
        PRIMARY KEY (id)
      )    ;

      CREATE TABLE IF NOT EXISTS credential(
        id varchar,
        user_id varchar,
        project_id varchar,
        type varchar,
        extra text,
        key_hash varchar,
        encrypted_blob text,
        PRIMARY KEY (id)
      )    ;

      CREATE TABLE IF NOT EXISTS endpoint(
        id varchar,
        legacy_endpoint_id varchar,
        interface varchar,
        service_id varchar,
        url text,
        extra text,
        enabled boolean,
        region_id varchar,
        PRIMARY KEY (id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON endpoint(service_id)    ;
      CREATE INDEX IF NOT EXISTS ON endpoint(region_id)    ;

      CREATE TABLE IF NOT EXISTS endpoint_group(
        id varchar,
        name varchar,
        description text,
        filters text,
        PRIMARY KEY (id)
      )    ;

      CREATE TABLE IF NOT EXISTS federated_user(
        id varchar,
        user_id varchar,
        idp_id varchar,
        protocol_id varchar,
        unique_id varchar,
        display_name varchar,
        PRIMARY KEY (id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON federated_user(user_id);
      CREATE INDEX IF NOT EXISTS ON federated_user(idp_id);
      CREATE INDEX IF NOT EXISTS ON federated_user(protocol_id);

      CREATE TABLE IF NOT EXISTS federation_protocol(
        id varchar,
        idp_id varchar,
        mapping_id varchar,
        PRIMARY KEY (id, idp_id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON federation_protocol(idp_id);

      CREATE TABLE IF NOT EXISTS group_(
        id varchar,
        domain_id varchar,
        name varchar,
        description text,
        extra text,
        PRIMARY KEY (id)
      );

      CREATE INDEX IF NOT EXISTS ON group_(domain_id);

      CREATE TABLE IF NOT EXISTS id_mapping(
        public_id varchar,
        domain_id varchar,
        local_id varchar,
        entity_type varchar,
        PRIMARY KEY (public_id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON id_mapping(domain_id);

      CREATE TABLE IF NOT EXISTS identity_provider(
        id varchar,
        enabled boolean,
        description text,
        domain_id varchar,
        PRIMARY KEY (id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON identity_provider(domain_id);

      CREATE TABLE IF NOT EXISTS idp_remote_ids(
        idp_id varchar,
        remote_id varchar,
        PRIMARY KEY (remote_id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON idp_remote_ids(idp_id);

      CREATE TABLE IF NOT EXISTS implied_role(
        prior_role_id varchar,
        implied_role_id varchar,
        PRIMARY KEY (prior_role_id, implied_role_id)
      )    ;

      CREATE TABLE IF NOT EXISTS local_user(
        id varchar,
        user_id varchar,
        domain_id varchar,
        name varchar,
        failed_auth_count int,
        failed_auth_at timestamp,
        PRIMARY KEY (id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON local_user(user_id);
      CREATE INDEX IF NOT EXISTS ON local_user(domain_id);


      CREATE TABLE IF NOT EXISTS mapping(
        id varchar,
        rules text,
        PRIMARY KEY (id)
      )    ;

      CREATE TABLE IF NOT EXISTS migrate_version(
        repository_id varchar,
        repository_path text,
        version int,
        PRIMARY KEY (repository_id)
      )    ;

      CREATE TABLE IF NOT EXISTS nonlocal_user(
        domain_id varchar,
        name varchar,
        user_id varchar,
        PRIMARY KEY (domain_id, name)
      )    ;

      CREATE INDEX IF NOT EXISTS ON nonlocal_user(user_id);

      CREATE TABLE IF NOT EXISTS password(
        id varchar,
        local_user_id varchar,
        password varchar,
        expires_at timestamp,
        self_service boolean,
        password_hash varchar,
        created_at timestamp,
        PRIMARY KEY (id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON password(local_user_id);

      CREATE TABLE IF NOT EXISTS policy(
        id varchar,
        type varchar,
        blob text,
        extra text,
        PRIMARY KEY (id)
      )    ;

      CREATE TABLE IF NOT EXISTS policy_association(
        id varchar,
        policy_id varchar,
        endpoint_id varchar,
        service_id varchar,
        region_id varchar,
        PRIMARY KEY (id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON policy_association(endpoint_id);

      CREATE TABLE IF NOT EXISTS project(
        id varchar,
        name varchar,
        extra text,
        description text,
        enabled boolean,
        domain_id varchar,
        parent_id varchar,
        is_domain boolean,
        PRIMARY KEY (id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON project(domain_id);
      CREATE INDEX IF NOT EXISTS ON project(parent_id);

      CREATE TABLE IF NOT EXISTS project_endpoint(
        endpoint_id varchar,
        project_id varchar,
        PRIMARY KEY (endpoint_id, project_id)
      )    ;

      CREATE TABLE IF NOT EXISTS project_endpoint_group(
        endpoint_group_id varchar,
        project_id varchar,
        PRIMARY KEY (endpoint_group_id, project_id)
      )    ;

      CREATE TABLE IF NOT EXISTS project_tag(
        project_id varchar,
        name varchar,
        PRIMARY KEY (project_id, name)
      )    ;

      CREATE TABLE IF NOT EXISTS region(
        id varchar,
        description varchar,
        parent_region_id varchar,
        extra text,
        PRIMARY KEY (id)
      )    ;

      CREATE TABLE IF NOT EXISTS request_token(
        id varchar,
        request_secret varchar,
        verifier varchar,
        authorizing_user_id varchar,
        requested_project_id varchar,
        role_ids text,
        consumer_id varchar,
        expires_at varchar,
        PRIMARY KEY (id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON request_token(consumer_id);

      CREATE TABLE IF NOT EXISTS revocation_event(
        id varchar,
        domain_id varchar,
        project_id varchar,
        user_id varchar,
        role_id varchar,
        trust_id varchar,
        consumer_id varchar,
        access_token_id varchar,
        issued_before timestamp,
        expires_at timestamp,
        revoked_at timestamp,
        audit_id varchar,
        audit_chain_id varchar,
        PRIMARY KEY (id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON revocation_event(project_id);
      CREATE INDEX IF NOT EXISTS ON revocation_event(user_id);
      CREATE INDEX IF NOT EXISTS ON revocation_event(issued_before);
      CREATE INDEX IF NOT EXISTS ON revocation_event(revoked_at);
      CREATE INDEX IF NOT EXISTS ON revocation_event(audit_id);

      CREATE TABLE IF NOT EXISTS role(
        id varchar,
        name varchar,
        extra text,
        domain_id varchar,
        PRIMARY KEY (id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON role(name);

      CREATE TABLE IF NOT EXISTS sensitive_config(
        domain_id varchar,
        group_ varchar,
        option varchar,
        value text,
        PRIMARY KEY (domain_id, group_, option)
      )    ;

      CREATE TABLE IF NOT EXISTS service(
        id varchar,
        type varchar,
        enabled boolean,
        name varchar,
        description text,
        PRIMARY KEY (id)
      )    ;

      CREATE TABLE IF NOT EXISTS service_provider(
        auth_url varchar,
        id varchar,
        enabled boolean,
        description text,
        sp_url varchar,
        relay_state_prefix varchar,
        PRIMARY KEY (id)
      )    ;

      CREATE TABLE IF NOT EXISTS token_(
        id varchar,
        expires timestamp,
        extra text,
        valid boolean,
        trust_id varchar,
        user_id varchar,
        PRIMARY KEY (id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON token_(expires);
      CREATE INDEX IF NOT EXISTS ON token_(trust_id);
      CREATE INDEX IF NOT EXISTS ON token_(user_id);

      CREATE TABLE IF NOT EXISTS trust(
        id varchar,
        trustor_user_id varchar,
        trustee_user_id varchar,
        project_id varchar,
        impersonation boolean,
        deleted_at timestamp,
        expires_at timestamp,
        remaining_uses int,
        allow_redelegation boolean,
        redelegated_trust_id varchar,
        redelegation_count int,
        extra text,
        PRIMARY KEY (id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON trust(trustor_user_id);

      CREATE TABLE IF NOT EXISTS trust_role(
        trust_id varchar,
        role_id varchar,
        PRIMARY KEY (trust_id, role_id)
      )    ;

      CREATE TABLE IF NOT EXISTS user_(
        id varchar,
        extra text,
        enabled boolean,
        default_project_id varchar,
        created_at timestamp,
        last_active_at timestamp,
        domain_id varchar,
        PRIMARY KEY (id)
      )    ;

      CREATE INDEX IF NOT EXISTS ON user_(default_project_id);
      CREATE INDEX IF NOT EXISTS ON user_(domain_id);

      CREATE TABLE IF NOT EXISTS user_group_membership(
        user_id varchar,
        group_id varchar,
        PRIMARY KEY (user_id, group_id)
      )    ;

      CREATE TABLE IF NOT EXISTS user_option(
        user_id varchar,
        option_id varchar,
        option_value text,
        PRIMARY KEY (user_id, option_id)
      )    ;

      CREATE TABLE IF NOT EXISTS whitelisted_config(
        domain_id varchar,
        group_ varchar,
        option varchar,
        value text,
        PRIMARY KEY (domain_id, group_, option)
      )    ;
    CONSISTENCY ONE;

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


