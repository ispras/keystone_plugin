local redis = require "resty.redis"
local kutils = require ("kong.plugins.keystone.utils")

local function connect_to_redis(conf)
    local red = redis:new()
    local err

    conf, err = kutils.config_from_dao(conf)
    if not conf then
        return nil, "failed to get configuration parameters: "..err
    end
    red:set_timeout(conf.matchmaker_redis_wait_timeout)

    local cjson = require ("cjson")
--    error(cjson.encode({conf.matchmaker_redis_host, conf.matchmaker_redis_port}))
    if not conf.matchmaker_redis_host or not conf.matchmaker_redis_port then
        error(cjson.encode(conf))
    end
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