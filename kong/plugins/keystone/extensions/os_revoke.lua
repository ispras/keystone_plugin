local responses = require "kong.tools.responses"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")

local function list_revocation_events (self, dao_factory)
    local events, err = dao_factory.revocation_event:find_all()
    kutils.assert_dao_error(err, "revocation event find all")
    if self.params.since then
        local last = 1
        for _, v in ipairs(events) do
            if v.revoked_at and v.revoked_at > self.params.since then
                events[last] = v
                last = last + 1
            end
        end
        for i = last, #events do
            events[i] = nil
        end
    end
    for i, _ in pairs(events) do
        events[i].issued_before = events[i].issued_before and kutils.time_to_string(events[i].issued_before) or nil
        events[i].expires_at = events[i].expires_at and kutils.time_to_string(events[i].expires_at) or nil
        events[i].revoked_at = events[i].revoked_at and kutils.time_to_string(events[i].revoked_at) or nil
    end

    return 200, { events = events }
end

local routes = {
    ['/v3/OS-REVOKE/events'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_revocation_events", dao_factory, self.params)
            responses.send(list_revocation_events(self, dao_factory))
        end
    }
}

return {
    routes = routes
}