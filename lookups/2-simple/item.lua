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

-- Module categories to modules with that category
-- Format:
--   module_category_name --> module_name --> true | nil
stage.category_to_modules = function()
    local lu = LookupLib.lookup

    lu.category_to_modules = {}

    -- Every module category should be in the category_to_modules lookup, regardless of whether there is a module having that category
    for _, module_category in pairs(prots("module-category")) do
        lu.category_to_modules[module_category.name] = {}
    end

    for _, module_item in pairs(prots("module")) do
        lu.category_to_modules[module_item.category][module_item.name] = true
    end
end

return stage