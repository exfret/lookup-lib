-- This file also includes corresponding lookups for asteroid chunks since they are easier to group together with entity lookups

-- START repeated header
-- Maintenance-wise, it's easiest to keep this exact header for all stage 2 lookups, even if not all these are used

local collision_mask_util = require("__core__.lualib.collision-mask-util")
local categories = DataRawLib.categories
local extract = DataRawLib.extract
local key = DataRawLib.key.key
local concat = DataRawLib.key.concat
local mtm = DataRawLib.mtm
local room = DataRawLib.room
local base_prots = DataRawLib.traversal.base_prots
local find_prot = DataRawLib.traversal.find_prot
local prots = DataRawLib.traversal.prots
local tablize = DataRawLib.traversal.tablize
local listify = DataRawLib.traversal.listify
local trigger_lib = DataRawLib.trigger

local stage = {}

-- END repeated header

-- Entities to py creature module categories that can be used to operate them
-- Format:
--   entitiy_name --> module_category_name --> true | nil
local pyal_building_modules = {}
if mods["pyalienlife"] then
    pyal_building_modules = require("__pyalienlife__.scripts.farming.farm-building-list")
end
local pyae_building_modules = {}
if mods["pyalternativeenergy"] then
    pyae_building_modules = require("__pyalternativeenergy__.scripts.farming")
end
stage.py_operability_module_cats = function()
    local lu = LookupLib.lookup

    lu.py_operability_module_cats = {}

    local building_modules = {}
    for _, module_list in pairs({pyal_building_modules, pyae_building_modules}) do
        for building, spec in pairs(module_list) do
            building_modules[building] = spec
        end
    end
    
    for building, spec in pairs(building_modules) do
        -- spec.default_module is the tier one module for the module category required for a building (according to py dev)
        mtm.insert(lu.py_operability_module_cats, {building, data.raw.module[spec.default_module].category})
    end
end

return stage