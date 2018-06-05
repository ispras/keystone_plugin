local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")

local function list_project_tags(self, dao_factory)
    local tags = {}
    local temp, err = dao_factory.project_tag:find_all({project_id = self.params.project_id})
    kutils.assert_dao_error(err, "project_tag:find_all")
    for i = 1, kutils.list_limit(#temp) do
        tags[i] = temp[i].name
    end

    return {tags = tags}
end

local function check_project_tag(self, dao_factory)
    local temp, err = dao_factory.project_tag:find({project_id = self.params.project_id, name = self.params.tag})
    kutils.assert_dao_error(err, "project_tag:find")
    if not temp then
        responses.send_HTTP_BAD_REQUEST()
    end
    responses.send_HTTP_NO_CONTENT()
end

local function add_project_tag(self, dao_factory)
    local _, err = dao_factory.project_tag:insert({project_id = self.params.project_id, name = self.params.tag})
    kutils.assert_dao_error(err, "project_tag:insert")


    responses.send_HTTP_CREATED(list_project_tags(self, dao_factory))
end

local function modify_project_tag(self, dao_factory)
    local new_tags = self.params.tags
    local tags, err = dao_factory.project_tag:find_all({project_id = self.params.project_id})
    kutils.assert_dao_error(err, "project_tag:find_all")
    for i = 1, #new_tags do
        local j = kutils.has_id(tags, new_tags[i], 'name')
        if j then
            new_tags[i] = nil
            tags[j] = nil
        end
    end

    for _, v  in pairs(new_tags) do
        local _, err = dao_factory.project_tag:insert({project_id = self.params.project_id, name = v})
        kutils.assert_dao_error(err, "project_tag:insert")
    end

    for _, v in pairs(tags) do
        local _, err = dao_factory.project_tag:delete(v)
        kutils.assert_dao_error(err, "project_tag:delete")
    end

    responses.send_HTTP_OK({tags = new_tags})
end

local function delete_project_tag(self, dao_factory)
    local _, err = dao_factory.project_tag:delete({project_id = self.params.project_id, name = self.params.tag})
    kutils.assert_dao_error(err, "project_tag:delete")

    responses.send_HTTP_NO_CONTENT()
end

local function remove_all_project_tags(self, dao_factory)
    local tags, err = dao_factory.project_tag:find_all({project_id = self.params.project_id})
    kutils.assert_dao_error(err, "project_tag:find_all")

    for _, v in pairs(tags) do
        local _, err = dao_factory.project_tag:delete(v)
        kutils.assert_dao_error(err, "project_tag:delete")
    end

    responses.send_HTTP_NO_CONTENT()
end

local routes = {
    ['/v3/projects/:project_id/tags'] = {
        GET = function (self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_project_tags", dao_factory, self.params)
            responses.send_HTTP_OK(list_project_tags(self, dao_factory))
        end,
        PUT = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:modify_project_tag", dao_factory, self.params)
            modify_project_tag(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:remove_all_project_tags", dao_factory, self.params)
            remove_all_project_tags(self, dao_factory)
        end
    },
    ['/v3/projects/:project_id/tags/:tag'] = {
        GET = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:check_project_tag", dao_factory, self.params)
            check_project_tag(self, dao_factory)
        end,
        PUT = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:add_project_tag", dao_factory, self.params)
            add_project_tag(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:delete_project_tag", dao_factory, self.params)
            delete_project_tag(self, dao_factory)
        end
    }
}
return routes