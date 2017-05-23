return 
  {
    name = "keystone",
    up = [[
      CREATE TABLE IF NOT EXISTS user_info(
        user_id uuid,
	tenant_id uuid,
        user_name text,
        password text,
	email text,
        enabled boolean,
        PRIMARY KEY (user_id)
      );
      
      CREATE INDEX IF NOT EXISTS ON user_info(user_name);

      CREATE TABLE IF NOT EXISTS tenant_info(
        tenant_id uuid,
        tenant_name text,
        description text,
        enabled boolean,
        PRIMARY KEY (tenant_id)
      );
   
      CREATE INDEX IF NOT EXISTS ON tenant_info(tenant_name);

      CREATE TABLE IF NOT EXISTS token_info(
	token_id uuid,
        user_id uuid,
        tenant_id uuid,
        issued_at timestamp,
	expires timestamp,
        PRIMARY KEY (token_id)
      );

      CREATE INDEX IF NOT EXISTS ON token_info(user_id);
      
      CREATE TABLE IF NOT EXISTS uname_to_uid(
	user_name text,
	user_id uuid,
	PRIMARY KEY (user_name)
      );

      CREATE INDEX IF NOT EXISTS ON uname_to_uid(user_id);
    
      CREATE TABLE IF NOT EXISTS tenname_to_tenid(
        tenant_name text, 
        tenant_id uuid,
        PRIMARY KEY (tenant_name)
      );

      CREATE INDEX IF NOT EXISTS ON tenname_to_tenid(tenant_id);

    ]],
    down = [[
      DROP TABLE uid_to_uinfo;
      DROP TABLE tenid_to_teninfo;
      DROP TABLE tokenid_to_tokeninfo;
      DROP TABLE uname_to_uid;
      DROP TABLE tenname_to_tenid;
    ]]
}


