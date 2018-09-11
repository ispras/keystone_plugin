local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local kutils = require ("kong.plugins.keystone.utils")
local policies = require ("kong.plugins.keystone.policies")
local cjson = require 'cjson'

local Region = {}

local function list_regions(self, dao_factory)
    local resp = {
        links = {
            next = cjson.null,
            previous = cjson.null,
            self = self:build_url(self.req.parsed_url.path)
        },
        regions = {}
    }

    local regions = {}
    local err
    if self.params.parent_region_id then
        regions, err = dao_factory.region:find_all({parent_region_id = self.params.parent_region_id})
    else
        regions, err = dao_factory.region:find_all()
    end
    kutils.assert_dao_error(err, "region:find_all")

    if not next(regions) then
        responses.send_HTTP_OK(resp)
    end

    for i = 1, kutils.list_limit(#regions, self.config) do
        resp.regions[i] = {}
        resp.regions[i].description = regions[i].description
        resp.regions[i].id = regions[i].id
        resp.regions[i].links = {
                self = self:build_url(self.req.parsed_url.path)
        }
        resp.regions[i].parent_region_id = regions[i].parent_region_id
    end
    responses.send_HTTP_OK(resp)
end

local function create_region(self, dao_factory)
    local request = self.params
    if not request.region then
        return responses.send_HTTP_BAD_REQUEST("Region is nil, check self.params")
    end

    local region_obj = {}
    region_obj.description = request.region.description
    region_obj.id = request.region.id or utils.uuid()

    local res, err = dao_factory.region:find({id = region_obj.id})
    kutils.assert_dao_error(err, "region find")
    if res then
        responses.send_HTTP_CONFLICT("Error: region with this id exists")
    end

    if request.region.parent_region_id then
        local parent_region, err = dao_factory.region:find({id=request.region.parent_region_id})
        kutils.assert_dao_error(err, "region find")
        if not parent_region then
            responses.send_HTTP_BAD_REQUEST("Error: parent region doesn't exist")
        end
        region_obj.parent_region_id = request.region.parent_region_id
    end

    local region, err = dao_factory.region:insert(region_obj)
    kutils.assert_dao_error(err, "region insert")
    if not region then
            responses.send_HTTP_CONFLICT({error = err, object = region_obj})
    end

    region.links = {
                self = self:build_url(self.req.parsed_url.path)
            }

    local response = {region = region}
    responses.send_HTTP_CREATED(response)
end

local function get_region_info(self, dao_factory)
    local region_id = self.params.region_id
    if not region_id then
        responses.send_HTTP_BAD_REQUEST("Error: bad region id")
    end

    local region, err = dao_factory.region:find({id=region_id})
    kutils.assert_dao_error(err, "region find")
    if not region then
        return responses.send_HTTP_BAD_REQUEST("Error: no such region in the system")
    end

    region.links = {
                self = self:build_url(self.req.parsed_url.path)
    }
    local response = {region = region}
    responses.send_HTTP_OK(response)
end

local function update_region(self, dao_factory)
    local region_id = self.params.region_id
    if not region_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad region id")
    end

    local region, err = dao_factory.region:find({id=region_id})
    kutils.assert_dao_error(err, "region find")
    if not region then
        return responses.send_HTTP_BAD_REQUEST("Error: no such region in the system")
    end

    local request = self.params
    if not request.region then
         return responses.send_HTTP_BAD_REQUEST("Region is nil, check self.params")
    end

    if request.region.parent_region_id then
        local _, err = dao_factory.region:find({id=request.region.parent_region_id})
        kutils.assert_dao_error(err, "region find")
    end

    local updated_region, err = dao_factory.region:update(request.region, {id=region.id})
    kutils.assert_dao_error(err, "region update")

    updated_region.links = {
                self = self:build_url(self.req.parsed_url.path)
    }
    local response = {region = updated_region}
    return responses.send_HTTP_OK(response)
end

local function delete_region(self, dao_factory)
    local region_id = self.params.region_id
    if not region_id then
        return responses.send_HTTP_BAD_REQUEST("Error: bad region id")
    end

    local region, err = dao_factory.region:find({id=region_id})
    kutils.assert_dao_error(err, "region find")
    if not region then
        return responses.send_HTTP_BAD_REQUEST("Error: no such region in the system")
    end

    local child, err = dao_factory.region:find_all({parent_region_id = region_id})
    kutils.assert_dao_error(err, "region find_all")
    if next(child) then
        return responses.send_HTTP_CONFLICT("Error: this region has child regions")
    end

    local _, err = dao_factory.region:delete({id = region_id})
    kutils.assert_dao_error(err, "region delete")

    return responses.send_HTTP_NO_CONTENT()
end

Region.list_regions = list_regions
Region.create_region = create_region
Region.get_region_info = get_region_info
Region.update_region = update_region
Region.delete_region = delete_region

return {
    ["/v3/regions"] = {
        GET = function(self, dao_factory)
            policies.check(self, dao_factory, "identity:list_regions")
            Region.list_regions(self, dao_factory)
        end,
        POST = function(self, dao_factory)
            policies.check(self, dao_factory, "identity:create_region")
            Region.create_region(self, dao_factory)
        end
    },
    ["/v3/regions/:region_id"] = {
        GET = function(self, dao_factory)
            policies.check(self, dao_factory, "identity:get_region")
            Region.get_region_info(self, dao_factory)
        end,
        PATCH = function(self, dao_factory)
            policies.check(self, dao_factory, "identity:update_region")
            Region.update_region(self, dao_factory)
        end,
        DELETE = function(self, dao_factory)
            policies.check(self, dao_factory, "identity:delete_region")
            Region.delete_region(self, dao_factory)
        end
    }
}