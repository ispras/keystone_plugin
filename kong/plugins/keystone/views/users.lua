User = {}

function list_users(self, dao_factory)
    return ''
end

function create_user(self, dao_factory)
    return ''
end

function get_user_info(self, dao_factory)
    return ''
end

function update_user(self, dao_factory)
    return ''
end

function delete_user(self, dao_factory)
    return ''
end

function list_user_groups(self, dao_factory)
    return ''
end

function list_user_projects(self, dao_factory)
    return ''
end

function change_user_password(self, dao_factory)
    return ''
end

User.list_users = list_users
User.create_user = create_user
User.get_user_info = get_user_info
User.update_user = update_user
User.delete_user = delete_user
User.list_user_groups = list_user_groups
User.list_user_projects = list_user_projects
User.change_user_password = change_user_password

return User