return {
  {
    name = "keystone",
    up = [[
      CREATE TABLE IF NOT EXISTS keystone_user_info(
        user_id uuid,
	    tenant_id uuid,
        user_name text,
        password text,
	    email text,
        enabled boolean,
        PRIMARY KEY (user_id)
      );
      
      CREATE INDEX IF NOT EXISTS ON keystone_user_info(user_name);

      CREATE TABLE IF NOT EXISTS keystone_tenant_info(
        tenant_id uuid,
        tenant_name text,
        description text,
        enabled boolean,
        PRIMARY KEY (tenant_id)
      );
   
      CREATE INDEX IF NOT EXISTS ON keystone_tenant_info(tenant_name);

      CREATE TABLE IF NOT EXISTS keystone_token_info(
	    token_id uuid,
        user_id uuid,
        tenant_id uuid,
        issued_at timestamp,
	    expires timestamp,
        PRIMARY KEY (token_id)
      );
      
      CREATE TABLE IF NOT EXISTS keystone_uname_to_uid(
	    user_name text,
	    user_id uuid,
	    PRIMARY KEY (user_name)
      );

      CREATE INDEX IF NOT EXISTS ON keystone_uname_to_uid(user_id);
    
      CREATE TABLE IF NOT EXISTS keystone_tenname_to_tenid(
        tenant_name text, 
        tenant_id uuid,
        PRIMARY KEY (tenant_name)
      );

      CREATE INDEX IF NOT EXISTS ON keystone_tenname_to_tenid(tenant_id);

    ]],
    down = [[
      DROP TABLE keystone_user_info;
      DROP TABLE keystone_tenant_info;
      DROP TABLE keystone_token_info;
      DROP TABLE keystone_uname_to_uid;
      DROP TABLE keystone_tenname_to_tenid;
    ]]
  }
}
