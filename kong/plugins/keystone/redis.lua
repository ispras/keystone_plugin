local redis = require "resty.redis"
local kutils = require ("kong.plugins.keystone.utils")

local function connect_to_redis(conf)
    local red = redis:new()
    local err

    conf, err = conf or kutils.config_from_dao()
    if not conf then
        return nil, "failed to get configuration parameters: "..err
    end
    red:set_timeout(conf.matchmaker_redis_wait_timeout)

    local ok, err = red:connect(conf.matchmaker_redis_host, conf.matchmaker_redis_port)
    if err then
        return nil, err
    end

    if conf.matchmaker_redis_password and conf.matchmaker_redis_password ~= "" then
        local ok, err = red:auth(conf.matchmaker_redis_password)
        if err then
            return nil, err
        end
    end

    return red
end

return {
    connect = connect_to_redis
}