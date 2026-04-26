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

-- Asteroids and asteroid chunks to space places where they appear
-- Format:
--   asteroid_key --> space_place_key --> true | nil
stage.asteroid_to_places = function()
    local lu = LookupLib.lookup

    lu.asteroid_to_places = {}

    for loc_key, loc in pairs(lu.space_places) do
        local loc_prot = find_prot(loc.type, loc.name)
        -- Try to handle both space location and connection spawn definitions at once
        for _, spawn_def in pairs(tablize(loc_prot.asteroid_spawn_definitions)) do
            if spawn_def.asteroid ~= nil then
                mtm.insert(lu.asteroid_to_places, {key(spawn_def.type or "entity", spawn_def.asteroid), loc_key})
            else
                for entity_id, _ in pairs(spawn_def) do
                    mtm.insert(lu.asteroid_to_places, {key("entity", entity_id), loc_key})
                end
            end
        end
    end
end

-- Autoplaceables (tiles/entities) to planets where they appear
-- Format:
--   autoplaceable_key --> planet_name --> true | nil
stage.autoplaceable_to_planets = function()
    local lu = LookupLib.lookup

    lu.autoplaceable_to_planet = {}

    local check_on_planet = DataRawLib.map_gen.check_on_planet
    
    for _, planet in pairs(prots("planet")) do
        for _, autoplaceable_type in pairs({"entity", "tile"}) do
            for prot_name, _ in pairs(check_on_planet(planet.name, autoplaceable_type)) do
                mtm.insert(lu.autoplaceable_to_planet, {key(autoplaceable_type, prot_name), planet.name})
            end
        end
    end
end

return stage