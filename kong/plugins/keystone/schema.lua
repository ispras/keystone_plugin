local Errors = require "kong.dao.errors"
local redis = require "kong.plugins.keystone.redis"

return {
  no_consumer = true,
  fields = {
    redis_port = { type = "number", default = 6379 },
    redis_host = { type = "string", default = '127.0.0.1' },
    redis_timeout = { type = "number", default = 2000 },
    redis_password = { type = "string", default = '' }
  },
  self_check = function(schema, conf, dao, is_updating)
        local red, err = redis.connect(conf)
        if err then
          return false, Errors.schema(err)
        end

        return true
    end
}

