local responses = require "kong.tools.responses"
local crud = require "kong.api.crud_helpers"
local cjson = require "cjson"
local utils = require "kong.tools.utils"

Project = {}

local function list_projects(self, dao_factory)
    ngx.req.read_body()
    local request = ngx.req.get_body_data()

    filter_params = {}
    if request then
        request = cjson.decode(request)
        filter_params = request
    end



    return ''

end

local function create_project(self, dao_factory)
    ngx.req.read_body()
    local request = ngx.req.get_body_data()

    local name = request.project.name -- must be checked that name is unique
    if not name then
        return responses.send_HTTP_BAD_REQUEST("Error: project name must be in the request")
    end

    local res, err = dao_factory.project:find_all({name=name})
    if res then
        return responses.send_HTTP_BAD_REQUEST("Error: project with this name exists")
    end

    local is_domain = request.project.is_domain or false
    local description = request.project.description or ''
    local domain_id = request.project.domain_id --must be supplemented
    local enabled = request.project.enabled or true
    local parent_id = request.project.parent_id --must be supplemented
    local id = utils.uuid()

    local project_obj = {
        id = id,
        name = name,
        description = description,
        enabled = enabled,
        domain_id = domain_id,
        parent_id = parent_id,
        is_domain = is_domain
    }

    local res, err = dao_factory.project:insert(project_obj)

    if err then
            return responses.send_HTTP_CONFLICT(err)
    end

    project_obj.links = {
                self = self:build_url(self.req.parsed_url.path)
            }

    local response = {project = project_obj}
    return responses.send_HTTP_CREATED(response)
end

local function get_project_info(self, dao_factory)
    local project_id = self.params.project_id
    if not project_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad project id")
    end

    local project, err = dao_factory.project:find{id=project_id}
    if err then
        return responses.send_HTTP_BAD_REQUEST("Error: bad project id")
    end

    local project_obj = {
        is_domain = project.is_domain,
        description = project.description,
        domain_id = project.domain_id,
        enabled = project.enabled,
        id = project.id,
        links = {
                self = self:build_url(self.req.parsed_url.path)
            },
        name = project.name,
        parent_id = project.parent_id
    }

    ngx.req.read_body()
    local request = ngx.req.get_body_data()

    local response = {project = project_obj}
    return responses.send_HTTP_OK(response)
end

local function update_project(self, dao_factory)
    return ''
end

local function delete_project(self, dao_factory)
    return ''
end

Project.list_projects = list_projects
Project.create_project = create_project
Project.get_project_info = get_project_info
Project.update_project = update_project
Project.delete_project = delete_project

return {
    ["/v3/projects"] = {
        GET = function(self, dao_factory)
            projects.list_projects(self, dao_factory)
        end,
        POST = function(self, dao_factory)
            projects.create_project(self, dao_factory)
        end
    },
    ["/v3/projects/:project_id"] = {
        GET = function(self, dao_factory)
            projects.get_project_info(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            projects.update_project(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            projects.delete_project(self, dao_factory)
        end
    },
}