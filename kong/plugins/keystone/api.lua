local users = require("views.users")

return {
    ["/v3/users"] = {
        GET = function(self, dao_factory)
            users.list_users(self, dao_factory)
        end,
        POST = function(self, dao_factory)
            users.create_user(self, dao_factory)
        end
    },
    ["/v3/users/:user_id"] = {
        GET = function(self, dao_factory)
            users.get_user_info(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            users.update_user(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            users.delete_user(self, dao_factory)
        end
    },
    ["/v3/users/:user_id/groups"] = {
        GET = function(self, dao_factory)
            users.list_user_groups(self, dao_factory)
        end
    },
    ["/v3/users/:user_id/projects"] = {
        GET = function(self, dao_factory)
            users.list_user_projects(self, dao_factory)
        end
    },
    ["/v3/users/:user_id/password"] = {
        POST = function(self, dao_factory)
            users.change_user_password(self, dao_factory)
        end
    }
}