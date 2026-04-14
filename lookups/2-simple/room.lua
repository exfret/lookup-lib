-- START repeated header
-- Maintenance-wise, it's easiest to keep this exact header for all stage 2 lookups, even if not all these are used

local collision_mask_util = require("__core__/lualib/collision-mask-util")
local categories = DataRawLib.categories
local extract = DataRawLib.extract
local key = DataRawLib.key.key
local concat = DataRawLib.key.concat
local base_prots = DataRawLib.traversal.base_prots
local find_prot = DataRawLib.traversal.find_prot
local prots = DataRawLib.traversal.prots
local tablize = DataRawLib.traversal.tablize
local trigger_lib = DataRawLib.trigger

local stage = {}

-- END repeated header

stage.asteroid_to_places = function()
    local lu = LookupLib.lookup

    lu.asteroid_to_places = {}
    for _, chunk in pairs(prots("asteroid-chunk")) do
        lu.asteroid_to_places[key("asteroid-chunk", chunk.name)] = {}
    end
    for _, asteroid in pairs(prots("asteroid")) do
        lu.asteroid_to_places[key("entity", asteroid.name)] = {}
    end

    for loc_key, loc in pairs(lu.space_places) do
        local loc_prot = find_prot(loc.type, loc.name)
        -- Try to handle both space location and connection spawn definitions at once
        for _, spawn_def in pairs(tablize(loc_prot.asteroid_spawn_definitions)) do
            if spawn_def.asteroid ~= nil then
                lu.asteroid_to_places[key(spawn_def.type or "entity", spawn_def.asteroid)][loc_key] = true
            else
                for entity_id, _ in pairs(spawn_def) do
                    lu.asteroid_to_places[key("entity", entity_id)][loc_key] = true
                end
            end
        end
    end
end

-- TODO: rooms_spawning_entity

return stage