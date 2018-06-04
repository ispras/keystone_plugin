local responses = require "kong.tools.responses"
local crud = require "kong.api.crud_helpers"
local cjson = require "cjson"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")
local check_token_user = require ("kong.plugins.keystone.views.auth_and_tokens").check_token
local Project = {}

local subtree = {}
local subtrtee_as_ids = {}
local namespace_id

local function get_subtree_as_list(self, dao_factory, project) --not tested
    local child_projects, err = dao_factory.project:find_all({parent_id=project.id})
    kutils.assert_dao_error(err, "project find_all")
    if not child_projects then
        return
    end

    for child in child_projects do
        child.links = {self = self:build_url(self.req.parsed_url.path)}
        table.insert(subtree, child)
        get_subtree_as_list(self, dao_factory, child)
    end
end


local function get_subtree_as_ids(self, dao_factory, project) --not tested
    local child_projects, err = dao_factory.project:find_all({parent_id=project.id})
    kutils.assert_dao_error(err, "project find_all")
    if not child_projects then
        return
    end

    for child in child_projects do
        table.insert(subtree, child.id)
        get_subtree_as_ids(self, dao_factory, child)
    end
end

local function list_projects(self, dao_factory)
--    if true then
--        local conf = kutils.config_from_dao()
--        responses.send_HTTP_BAD_REQUEST(conf)
--    end
    local domain_id = self.params.domain_id
    local enabled = kutils.bool(self.params.enabled)
    local is_domain = kutils.bool(self.params.is_domain) or false
    local name = self.params.name
    local parent_id = self.params.parent_id

    local args = ( domain_id ~= nil or enabled ~= nil or is_domain ~= nil or name ~= nil or parent_id ~= nil ) and
            { domain_id = domain_id, enabled = enabled, is_domain = is_domain, name = name, parent_id = parent_id } or nil

    local resp
    if not self.params.domain then
        resp = {
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
            },
            projects = {}
        }

        local projects, err = dao_factory.project:find_all(args)
        kutils.assert_dao_error(err, "project:find_all")
        if not next(projects) then
            return responses.send_HTTP_OK(resp)
        end

        for i = 1, #projects do
            resp.projects[i] = {}
            resp.projects[i].description = projects[i].description
            resp.projects[i].domain_id = projects[i].domain_id or projects[i].id
            resp.projects[i].enabled = projects[i].enabled
            resp.projects[i].id = projects[i].id
            resp.projects[i].name = projects[i].name
            resp.projects[i].is_domain = projects[i].is_domain
            resp.projects[i].parent_id = projects[i].parent_id
            resp.projects[i].links = {
                self = resp.links.self..'/'..resp.projects[i].id
            }
            resp.projects[i].tags, err = dao_factory.project_tag:find_all({project_id = resp.projects[i].id})
            kutils.assert_dao_error(err, "project_tag:find_all")

        end
    else
        resp = {
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
            },
            domains = {}
        }

        local domains, err = dao_factory.project:find_all(args)
        kutils.assert_dao_error(err, "project:find_all")
        if not next(domains) then
            return responses.send_HTTP_OK(resp)
        end

        for i = 1, #domains do
            resp.domains[i] = {}
            resp.domains[i].description = domains[i].description
            resp.domains[i].enabled = domains[i].enabled
            resp.domains[i].id = domains[i].id
            resp.domains[i].name = domains[i].name
            resp.domains[i].links = {
                self = resp.links.self..'/'..resp.domains[i].id
            }
        end
    end
    return responses.send_HTTP_OK(resp)

end

local function check_project_name(dao_factory,name, is_domain, domain_id)
    is_domain = is_domain or false
    if is_domain then
        local res, err = dao_factory.project:find_all({name = name, is_domain = is_domain})
        kutils.assert_dao_error(err, "project:find_all")

        if next(res) then
            return res[1]
        end
    else
        local res, err = dao_factory.project:find_all({name = name, is_domain = is_domain, domain_id = domain_id})
        kutils.assert_dao_error(err, "project:find_all")

        if next(res) then
            return res[1]
        end
    end
end

local function check_project_domain(dao_factory, domain_id)
    local res, err = dao_factory.project:find({id = domain_id})
    kutils.assert_dao_error(err, "project:find")
    if not res or not res.is_domain then
        return responses.send_HTTP_CONFLICT("Error: domain with this ID does not exist")
    end
end

local function check_project_parent(dao_factory, parent_id, domain_id)
    local res, err = dao_factory.project:find({id = parent_id})
    kutils.assert_dao_error(err, "project:find")
    if not res or res.domain_id ~= domain_id then
        return responses.send_HTTP_CONFLICT("Error: parent project with this ID does not exist")
    end
end

local function create_project(self, dao_factory)
--    if true then
--        return responses.send_HTTP_BAD_REQUEST({params = self.params, request = self.req}) end -- TODO why self.params.domain not null?

    --ngx.req.read_body()
    --local request = ngx.req.get_body_data()
    --request = cjson.decode(request)
    local request = self.params
    if not request.project then
         responses.send_HTTP_BAD_REQUEST("Project is nil, check self.params")
    end
    --print(request)
    local name = request.project.name -- must be checked that name is unique
    if not name then
        responses.send_HTTP_BAD_REQUEST("Error: project name must be in the request")
    end

    local is_domain = kutils.bool(request.project.is_domain) or false
    local domain_id = request.project.domain_id

    if domain_id then
        check_project_domain(dao_factory, domain_id)
    else
        domain_id = 'default'
    end

    local project_obj = check_project_name(dao_factory, name, is_domain, domain_id)
    if project_obj then
        return 409, "Error: project with this name already exists"
    end

    local description = request.project.description or cjson.null

    local enabled = kutils.bool(request.project.enabled) or true
    local parent_id = request.project.parent_id --must be supplemented
    if parent_id then
        check_project_parent(dao_factory, parent_id, domain_id)
    end

    local id = request.project.id or utils.uuid()

    local project_obj = {
        id = id,
        name = name,
        description = description,
        enabled = enabled,
        domain_id = domain_id or id,
        parent_id = parent_id,
        is_domain = is_domain
    }

    local res, err = dao_factory.project:insert(project_obj)
--    kutils.assert_dao_error(err, "project:insert")
    kutils.assert_dao_error(err, domain_id)

    project_obj.links = {
                self = self:build_url(self.req.parsed_url.path)
            }

    local response
    if not self.params.domain then
        response = {project = project_obj }
    else
        response = {domain = {
                                name = project_obj.name,
                                description = project_obj.description,
                                enabled = project_obj.enabled,
                                id = project_obj.id,
                                links = project_obj.links
                            }
        }
    end
    return 201, response
end

local function get_project_info(self, dao_factory)
    local project_id = self.params.project_id
    if not project_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad project id")
    end

    local project, err

    if self.params.domain then
        project, err = dao_factory.project:find_all({id=project_id, is_domain = true})
        kutils.assert_dao_error(err, "project find_all")

        if not next(project) then
            project, err = dao_factory.project:find_all({name=project_id, is_domain = true, domain_id = namespace_id})
            kutils.assert_dao_error(err, "project find_all")
            if not next(project) then
                return responses.send_HTTP_BAD_REQUEST("No such project in the system")
            end
        end

        local domain = false
        for i = 1, #project do
            if project[i].is_domain then
                domain = true
                project = project[i]
                break
            end
        end

        if domain ~= true then
            return responses.send_HTTP_BAD_REQUEST("No such domain in the system")
        end
    else
        project, err = dao_factory.project:find({id=project_id})
        kutils.assert_dao_error(err, "project find")

        if not project then
            project, err = dao_factory.project:find_all({name=project_id, domain_id = namespace_id})
            kutils.assert_dao_error(err, "project find_all")
            if not next(project) then
                return responses.send_HTTP_BAD_REQUEST("No such project in the system")
            end

            local if_project_was = false
            for i = 1, #project do
                if project.domain_id == self.namespace_id then
                    project = project[i]
                    if_project_was = true
                    break
                end
            end
            if not if_project_was then
                return responses.send_HTTP_BAD_REQUEST("No such project in the system")
            end
        end
    end

    local project_obj = {
        is_domain = project.is_domain,
        description = project.description,
        domain_id = project.domain_id,
        enabled = project.enabled,
        id = project.id,
        links = {self = self:build_url(self.req.parsed_url.path)},
        name = project.name,
        parent_id = project.parent_id
    }

    --ngx.req.read_body()
    --local request = ngx.req.get_body_data()
    --request = cjson.decode(request)
    local request = self.params

    if request then --TODO test this
        if request.parents_as_list then
            parents = {}
            local cur_project = project_obj
            while true do
                if not cur_project.parent_id then
                    break
                end

                local parent, err = dao_factory.project:find({id=cur_project.parent_id})
                kutils.assert_dao_error(err, "project find")
                if not parent then
                    break
                end

                parent.links = {self = self:build_url(self.req.parsed_url.path)}
                table.insert(parents, parent)
                cur_project = parent
            end
            project_obj.parents = parents
        end

        if request.subtree_as_list then
            get_subtree_as_list(self, dao_factory, project_obj)
            project_obj.subtree = subtree
        end

        if request.parents_as_ids then
            parent_ids = {}
            local cur_project = project_obj
            while true do
                if not cur_project.parent_id then
                    break
                end

                local parent, err = dao_factory.project:find({id=cur_project.parent_id})
                kutils.assert_dao_error(err, "project find")
                if not parent then
                    break
                end

                table.insert(parents, parent.id)
                cur_project = parent
            end
            project_obj.parent_ids = parent_ids
        end

        if request.subtree_as_ids then
            get_subtree_as_ids()
            project_obj.subtree_ids = subtrtee_as_ids
        end
    end

    local response
    if not self.params.domain then
        response = {project = project_obj }
    else
        response = {domain = {
                                name = project_obj.name,
                                description = project_obj.description,
                                enabled = project_obj.enabled,
                                id = project_obj.id,
                                links = project_obj.links
                            }
        }
    end
    return responses.send_HTTP_OK(response)
end

local function update_project(self, dao_factory)
    local project_id = self.params.project_id
    if not project_id then
        responses.send_HTTP_BAD_REQUEST("Error: bad project id")
    end

    local project, err = dao_factory.project:find({id=project_id})
    kutils.assert_dao_error(err, "project find")
    if not project then
        responses.send_HTTP_BAD_REQUEST("Error: bad project id")
    end

--    ngx.req.read_body()
--    local request = ngx.req.get_body_data()
--    request = cjson.decode(request)
    local request = self.params
    if not request.project then
         return responses.send_HTTP_BAD_REQUEST("Project is nil, check self.params")
    end

    if request.project.name and request.project.name ~= project.name then
        local exists = check_project_name(dao_factory, request.project.name, project.is_domain, project.domain_id)
        if exists then
            responses.send_HTTP_CONFLICT("Error: project with this name already exists")
        end
    end

    local updated_project, err = dao_factory.project:update(request.project, {id=project.id})
    kutils.assert_dao_error(err, "project update")

    local response
    if not self.params.domain then
        response = {project = updated_project}
    else
        response = {domain = {
                                name = updated_project.name,
                                description = updated_project.description,
                                enabled = updated_project.enabled,
                                id = updated_project.id,
                                links = updated_project.links
                            }
        }
    end
    return responses.send_HTTP_OK(response)
end

local function delete_project(self, dao_factory)
    local project_id = self.params.project_id
    if not project_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad project id")
    end

    local _, err = dao_factory.project:find({id=project_id})
    kutils.assert_dao_error(err, "project find")

    local _, err = dao_factory.project:delete({id = project_id})
    kutils.assert_dao_error(err, "project delete")

    return responses.send_HTTP_NO_CONTENT()
end

Project.list_projects = list_projects
Project.create_project = create_project
Project.get_project_info = get_project_info
Project.update_project = update_project
Project.delete_project = delete_project

local routes = {
    ["/v3/projects"] = {
        GET = function(self, dao_factory)
--            responses.send_HTTP_OK(self.req.headers)
            policies.check(self.req.headers['X-Auth-Token'], "identity:list_projects", dao_factory, self.params, self.req.parsed_url.scheme == 'http')
            Project.list_projects(self, dao_factory)
        end,
        POST = function(self, dao_factory)
            policies.check(self.req.headers['X-Auth-Token'], "identity:create_project", dao_factory, self.params)
            responses.send(Project.create_project(self, dao_factory))
        end
    },
    ["/v3/projects/:project_id"] = {
        GET = function(self, dao_factory)
            namespace_id = policies.check(self.req.headers['X-Auth-Token'], "identity:get_project", dao_factory, self.params)
            Project.get_project_info(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            namespace_id = policies.check(self.req.headers['X-Auth-Token'], "identity:update_project", dao_factory, self.params)
            Project.update_project(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            namespace_id = policies.check(self.req.headers['X-Auth-Token'], "identity:delete_project", dao_factory, self.params)
            Project.delete_project(self, dao_factory)
        end
    }
}

return {routes = routes, create = create_project}