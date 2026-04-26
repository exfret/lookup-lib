-- This file also includes corresponding lookups for asteroid chunks since they are easier to group together with entity lookups

-- START repeated header
-- Maintenance-wise, it's easiest to keep this exact header for all stage 2 lookups, even if not all these are used

local collision_mask_util = require("__core__/lualib/collision-mask-util")
local categories = DataRawLib.categories
local extract = DataRawLib.extract
local key = DataRawLib.key.key
local concat = DataRawLib.key.concat
local mtm = DataRawLib.mtm
local base_prots = DataRawLib.traversal.base_prots
local find_prot = DataRawLib.traversal.find_prot
local prots = DataRawLib.traversal.prots
local tablize = DataRawLib.traversal.tablize
local listify = DataRawLib.traversal.listify
local trigger_lib = DataRawLib.trigger

local stage = {}

-- END repeated header

-- corpses to things that create them upon dying
-- Format:
--   corpse_name --> entity_name --> true | nil
stage.entities_with_corpse = function()
    local lu = LookupLib.lookup

    lu.entities_with_corpse = {}

    for _, entity in pairs(base_prots("entity")) do
        for _, corpse in pairs(listify(tablize(entity.corpse))) do
            lu.entities_with_corpse[corpse] = lu.entities_with_corpse[corpse] or {}
            lu.entities_with_corpse[corpse][entity.name] = true
        end
    end
end

-- Placeable entities to items that create them
-- Format:
--   entity_name --> item_name --> true | nil
stage.placeables = function()
    local lu = LookupLib.lookup

    lu.placeables = {}

    for _, item in pairs(base_prots("item")) do
        if item.place_result ~= nil then
            mtm.insert(lu.placeables, {item.place_result, item.name})
        end
    end
end

-- Plantable entities to items that create them
-- Format:
--   entity_name --> item_name --> true | nil
stage.plantables = function()
    local lu = LookupLib.lookup

    lu.plantables = {}

    for _, item in pairs(base_prots("item")) do
        if item.plant_result ~= nil then
            mtm.insert(lu.plantables, {item.plant_result, item.name})
        end
    end
end

-- unit-spawners that, when captured, result in this entity
stage.spawners_with_capture_result = function()
    local lu = LookupLib.lookup

    lu.spawners_with_capture_result = {}

    for _, spawner in pairs(prots("unit-spawner")) do
        local capture_result = spawner.captured_spawner_entity
        if capture_result ~= nil then
            mtm.insert(lu.spawners_with_capture_result, {capture_result, spawner.name})
        end
    end
end



-- CRITICAL TODO: Replace with general trigger framework
-- entities to things that create them on dying, usually with dying_trigger_effect
-- Format:
--   entity_name --> prot_key --> true | nil
stage.entity_dying_creators = function()
    local lu = LookupLib.lookup

    lu.entity_dying_creators = {}
    for _, entity in pairs(base_prots("entity")) do
        lu.entity_dying_creators[entity.name] = {}
    end

    local function add_to_entity_dying_creators(source_key, structs)
        local filtered_structs = trigger_lib.create_filters(structs)
        for _, create_struct in pairs(filtered_structs.creates_entity) do
            local entity_dying_creator = lu.entity_dying_creators[create_struct.entity]
            entity_dying_creator[source_key] = true
        end
    end

    for _, entity in pairs(base_prots("entity")) do
        -- entity dying effects
        local structs = {}
        trigger_lib.flatten_structs_item(tablize(entity.dying_trigger_effect), structs, "")
        local entity_source_key = key("entity", entity.name)
        add_to_entity_dying_creators(entity_source_key, structs)

        -- dying explosion
        if entity.dying_explosion ~= nil then
            if type(entity.dying_explosion) == "string" then
                lu.entity_dying_creators[entity.dying_explosion] = true
            else
                if entity.dying_explosion.name ~= nil then
                    lu.entity_dying_creators[entity.dying_explosion.name] = true
                else
                    for _, explosion in pairs(entity.dying_explosion) do
                        if type(explosion) == "string" then
                            lu.entity_dying_creators[explosion] = true
                        else
                            lu.entity_dying_creators[explosion.name] = true
                        end
                    end
                end
            end
        end
    end

    -- Not included:
    --  * tile's dying_trigger_effect etc. since tiles don't usually die under vanilla or even almost all modded circumstances
    --  * rocket silo rockets dying_explosino since I don't think that ever really does anything and am unfamiliar with what exactly that refers to
    --  * asteroid chunk dying_trigger_effect since I'm not sure when that triggers (asteroid chunks don't even have health)
end

return stage