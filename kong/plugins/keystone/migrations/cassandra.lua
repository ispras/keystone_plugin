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
        expires_at varchar,
        PRIMARY KEY (id)
      );

      CREATE INDEX IF NOT EXISTS ON access_token(authorizing_user_id);
      CREATE INDEX IF NOT EXISTS ON access_token(consumer_id);

      CREATE TABLE IF NOT EXISTS assignment(
        type varchar,
        actor_id varchar,
        target_id varchar,
        role_id varchar,
        inherited tinyint,
        PRIMARY KEY (type, actor_id, target_id, role_id, inherited)
      );

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
        PRIMARY KEY (id)
      );

      CREATE TABLE IF NOT EXISTS credential(
        id varchar,
        user_id varchar,
        project_id varchar,
        type varchar,
        extra text,
        key_hash varchar,
        encrypted_blob text,
        PRIMARY KEY (id)
      );

      CREATE TABLE IF NOT EXISTS endpoint(
        id varchar,
        legacy_endpoint_id varchar,
        interface varchar,
        service_id varchar,
        url text,
        extra text,
        enabled tinyint,
        region_id varchar,
        PRIMATY KEY (id)
      );

      CREATE INDEX IF NOT EXISTS ON endpoint(service_id);
      CREATE INDEX IF NOT EXISTS ON endpoint(region_id);

      CREATE TABLE IF NOT EXISTS endpoint_group(
        id varchar,
        name varchar,
        description text,
        filters text,
        PRIMARY KEY (id)
      );

      CREATE TABLE IF NOT EXISTS federated_user(
        id int,
        user_id varchar,
        idp_id varchar,
        protocol_id varchar,
        unique_id varchar,
        display_name varchar,
        PRIMARY KEY (id)
      );

      CREATE INDEX IF NOT EXISTS ON federated_user(user_id);
      CREATE INDEX IF NOT EXISTS ON federated_user(idp_id);
      CREATE INDEX IF NOT EXISTS ON federated_user(protocol_id);

      CREATE TABLE IF NOT EXISTS federation_protocol(
        id varchar,
        idp_id varchar,
        mapping_id varchar,
        PRIMARY KEY (id, idp_id)
      );

      CREATE TABLE IF NOT EXISTS group(
        id varchar,
        domain_id varchar,
        name varchar,
        description text,
        extra text,
        PRIMARY KEY (id)
      );

      CREATE INDEX IF NOT EXISTS ON group(domain_id);

      CREATE TABLE IF NOT EXISTS id_mapping(
        public_id varchar,
        domain_id varchar,
        local_id varchar,
        entity_type varchar,
        PRIMARY KEY (public_id)
      );

      CREATE INDEX IF NOT EXISTS ON id_mapping(domain_id);

      CREATE TABLE IF NOT EXISTS identity_provider(
        id varchar,
        enabled tinyint,
        description text,
        domain_id varchar,
        PRIMARY KEY (id)
      );

      CREATE INDEX IF NOT EXISTS ON identity_provider(domain_id);

      CREATE TABLE IF NOT EXISTS idp_remote_ids(
        idp_id varchar,
        remote_id varchar,
        PRIMARY KEY (remote_id)
      );

      CREATE INDEX IF NOT EXISTS ON idp_remote_ids(idp_id);

      CREATE TABLE IF NOT EXISTS implied_role(
        prior_role_id varchar,
        implied_role_id vachar,
        PRIMARY KEY (prior_role_id, implied_role_id)
      );

      CREATE TABLE IF NOT EXISTS local_user(
        id int,
        user_id varchar,
        domain_id varchar,
        name varchar,
        failed_auth_count int,
        failed_auth_at timestamp,
        PRIMARY_KEY (id)
      );

      CREATE INDEX IF NOT EXISTS ON local_user(user_id);
      CREATE INDEX IF NOT EXISTS ON local_user(domain_id);

      CREATE TABLE IF NOT EXISTS mapping(
        id varchar,
        rules text,
        PRIMARY KEY (id)
      );

      CREATE TABLE IF NOT EXISTS migrate_version(
        repository_id varchar,
        repository_path text,
        version int,
        PRIMARY KEY (repository_id)
      );

      CREATE TABLE IF NOT EXISTS nonlocal_user(
        domain_id varchar,
        name varchar,
        user_id varchar,
        PRIMARY KEY (domain_id, name)
      );

      CREATE INDEX IF NOT EXISTS ON nonlocal_user(user_id);

      CREATE TABLE IF NOT EXISTS password(
        id int,
        local_user_id int,
        password varchar,
        expires_at timestamp,
        self_service tinyint,
        password_hash varchar,
        created_at_int bigint,
        expires_at_int bigint,
        created_at timestamp,
        PRIMARY KEY (id)
      );

      CREATE INDEX IF NOT EXISTS ON password(local_user_id);

      CREATE TABLE IF NOT EXISTS policy(
        id varchar,
        type varchar,
        blob text,
        extra text,
        PRIMARY KEY (id)
      );

      CREATE TABLE IF NOT EXISTS policy_association(
        id varchar,
        policy_id varchar,
        endpoint_id varchar,
        service_id varchar,
        region_id varchar,
        PRIMARY KEY (id)
      );

      CREATE INDEX IF NOT EXISTS ON policy_association(endpoint_id);

      CREATE TABLE IF NOT EXISTS project(
        id varchar,
        name varchar,
        extra text,
        description text,
        enabled tinyint,
        domain_id varchar,
        parent_id varchar,
        is_domain tinyint,
        PRIMARY KEY (id)
      );

      CREATE INDEX IF NOT EXISTS ON project(domain_id);
      CREATE INDEX IF NOT EXISTS ON project(parent_id);

      CREATE TABLE IF NOT EXISTS project_endpoint(
        endpoint_id varchar,
        project_id varchar,
        PRIMARY KEY (endpoint_id, project_id)
      );

      CREATE TABLE IF NOT EXISTS project_endpoint_group(
        endpoint_group_id varchar,
        project_id varchar,
        PRIMARY KEY (endpoint_group_id, project_id)
      );

      CREATE TABLE IF NOT EXISTS project_tag(
        project_id varchar,
        name varchar,
        PRIMARY KEY (project_id, name)
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
      DROP TABLE group;
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
    ]]
  }
}
