-- This file also includes corresponding lookups for asteroid chunks since they are easier to group together with entity lookups

-- START repeated header
-- Maintenance-wise, it's easiest to keep this exact header for all stage 2 lookups, even if not all these are used

local collision_mask_util = require("__core__.lualib.collision-mask-util")
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

-- entities to tiles that they can be built on
-- Only considers entities with special buildability rules or tile restrictions
-- Note that although tile restrictions are defined on an entity's autoplace, they impact its general buildability as well
-- For other entities, this sends entity_name --> nil
-- If there are no tiles that this entity can be built on, it instead goes entity_name --> {}
-- Format:
--   entity_name --> tile_name --> true | nil
stage.entity_buildability_tiles = function()
    local lu = LookupLib.lookup

    lu.entity_buildability_tiles = {}

    for _, entity in pairs(base_prots("entity")) do
        if entity.tile_buildability_rules ~= nil or (entity.autoplace ~= nil and entity.autoplace.tile_restriction ~= nil) then
            local possible_tiles = {}
            for _, tile in pairs(prots("tile")) do
                possible_tiles[tile.name] = true
            end

            local restriction_tiles = {}
            if entity.autoplace ~= nil and entity.autoplace.tile_restriction ~= nil then
                for _, restriction in pairs(entity.autoplace.tile_restriction) do
                    -- Ignore transition restrictions; those could play a role but only in mods that force buildings to be on specific transitions and not either tile in isolation
                    -- That would require testing for each tile simultaneously, which doesn't seem worth the effort
                    if type(restriction) == "string" and possible_tiles[restriction] then
                        restriction_tiles[restriction] = true
                    end
                end
            else
                restriction_tiles = possible_tiles
            end

            local buildability_tiles = {}
            if entity.tile_buildability_rules ~= nil then
                for tile_name, _ in pairs(restriction_tiles) do
                    -- Test whether this tile satisfies the buildability rules
                    local tile = data.raw.tile[tile_name]
                    local satisfies_rules = true
                    for _, rule in pairs(entity.tile_buildability_rules) do
                        if rule.required_tiles ~= nil then
                            if not collision_mask_util.masks_collide(tile.collision_mask, rule.required_tiles) then
                                satisfies_rules = false
                            end
                        end
                        if rule.colliding_tiles ~= nil then
                            if collision_mask_util.masks_collide(tile.collision_mask, rule.colliding_tiles) then
                                satisfies_rules = false
                            end
                        end
                    end
                    if satisfies_rule then
                        buildability_tiles[tile_name] = true
                    end
                end
            else
                buildability_tiles = restriction_tiles
            end

            -- Finally test actual collision
            local non_colliding_tiles = {}
            for tile_name, _ in pairs(buildability_tiles) do
                local tile = data.raw.tile[tile_name]
                if not collision_mask_util.masks_collide(tile.collision_mask, entity.collision_mask or collision_mask_util.get_default_mask(entity.type)) then
                    non_colliding_tiles[tile_name] = true
                end
            end

            lu.entity_buildability_tiles[entity.name] = non_colliding_tiles
        end
    end
end

-- Entity to the collision group they correspond to, mostly used for determining entity buildability
-- Format:
--   entity_name --> collision_group_name
-- Also defines collision groups to the layers they correspond to
-- Format:
--   collision_group_name --> layer --> true | nil
stage.entity_to_collision_group = function()
    local lu = LookupLib.lookup

    lu.entity_to_collision_group = {}
    lu.collision_group_to_layers = {}

    for _, entity in pairs(base_prots("entity")) do
        local collision_layers = {}
        local collision_mask = entity.collision_mask or collision_mask_util.get_default_mask(entity.type)
        for layer, _ in pairs(collision_mask.layers) do
            table.insert(collision_layers, layer)
        end

        table.sort(collision_layers)
        local layers_key = concat(collision_layers)
        lu.entity_to_collision_group[entity.name] = layers_key
        mtm.insert(lu.collision_group_to_layers, {layers_key}, collision_layers)
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

return stage