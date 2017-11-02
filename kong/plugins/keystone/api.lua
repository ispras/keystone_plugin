local user = require("views/users")

return {
    ["/v3/users"] = {
        GET = function(self, dao_factory)
            user.list_users(self, dao_factory)
        end,
        POST = function(self, dao_factory)
            user.create_user(self, dao_factory)
        end
    },
    ["/v3/users/:user_id"] = {
        GET = function(self, dao_factory)
            user.get_user_info(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            user.update_user(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            user.delete_user(self, dao_factory)
        end
    },
    ["/v3/users/:user_id/groups"] = {
        GET = function(self, dao_factory)
            user.list_user_groups(self, dao_factory)
        end
    },
    ["/v3/users/:user_id/projects"] = {
        GET = function(self, dao_factory)
            user.list_user_projects(self, dao_factory)
        end
    },
    ["/v3/users/:user_id/password"] = {
        POST = function(self, dao_factory)
            user.change_user_password(self, dao_factory)
        end
    }
}