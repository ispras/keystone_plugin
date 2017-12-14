local redis = require "resty.redis"

local function config_from_file()
    local conf = {}
    local f, err = loadfile("/etc/kong/redis.conf", "t", conf)
    if f then
        f()
    else
        return nil, err
    end
    return {
        redis_host = conf.redis.host,
        redis_port = conf.redis.port,
        redis_timeout = conf.redis.timeout,
        redis_password = conf.redis.password or ''
    }
end

local function connect_to_redis(conf)
    local red = redis:new()
    local err

    conf, err = conf and conf or config_from_file()
    if not conf then
        return nil, "failed to get configuration parameters: "..err
    end
    red:set_timeout(conf.redis_timeout)

    local ok, err = red:connect(conf.redis_host, conf.redis_port)
    if err then
        return nil, err
    end

    if conf.redis_password and conf.redis_password ~= "" then
        local ok, err = red:auth(conf.redis_password)
        if err then
            return nil, err
        end
    end

    return red
end


local function red_set(premature, key, val, conf)
    local red, err = connect_to_redis(conf)
    if err then
        return nil, err
    end

    red:init_pipeline()
    red:set(key, val)
    local results, err = red:commit_pipeline()
    if err then
        return nil, err
    end
    return results
end

return {
    connect = connect_to_redis,
    set_value = red_set,
    config = config_from_file
}