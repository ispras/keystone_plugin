
return {
    bool = function (a)
        if type(a) == "string" then
            return a == "true"
        else
            return a
        end
    end,
    default_domain = function(dao_factory)
        local domain, err = dao_factory.project:find_all({name = 'default_domain'})
        if not err and next(domain) then return domain[1]['id'] end
        return nil
    end,
    handle_dao_error = function(resp, err, func)
        if not resp.errors then
            resp.errors = {num = 0 }
        end
        resp.errors.num = 1 + resp.errors.num
        resp.errors[resp.errors.num] = {error = err, func = func }
    end

}
