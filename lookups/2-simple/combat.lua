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

-- Maps ammo categories to things that can shoot that category
-- Format:
--   ammo_category_name --> prot_key --> true | nil
stage.ammo_category_sources = function()
    local lu = LookupLib.lookup

    lu.ammo_category_sources = {}
    for _, cat in pairs(prots("ammo-category")) do
        lu.ammo_category_sources[cat.name] = {}
    end

    for _, turret in pairs(prots("ammo-turret")) do
        for cat, _ in pairs(extract.ammo_categories(turret)) do
            lu.ammo_category_sources[cat][key("entity", turret.name)] = true
        end
    end

    for _, gun in pairs(prots("gun")) do
        for cat, _ in pairs(extract.ammo_categories(gun)) do
            lu.ammo_category_sources[cat][key("item", gun.name)] = true
        end
    end
end

-- Maps damage types to sources causing that damage, other than triggers
-- This inherently does not repeat prototypes, so we can store the sources as a list
-- Format:
--   damage_type_name --> list of source_info
-- source_info has keys:
--   damage: The table with damage info
--   start_type/start_name: The corresponding start/stop node types/names
stage.damage_type_to_sources = function()
    local lu = LookupLib.lookup

    lu.damage_type_to_sources = {}

    -- Excludes damage trigger effect (those are done separately in trigger lookup)
    -- Also excludes "special_neutral_target_damage" on streams because I have no clue what it does
    -- Lightning, since no one controls the weather
    -- Piercing damage, since it's borderline and not actually damage (would just be used to detect final_action)

    -- Fire inherent damage
    for _, fire in pairs(prots("fire")) do
        local damage = fire.damage_per_tick
        mtm.append(lu.damage_type_to_sources, {damage.type}, {
            start_type = "entity",
            start_name = fire.name,
            damage = damage,
            edge_desc = "fire-does-damage",
        })
    end

    -- Sticker inherent damage
    for _, sticker in pairs(prots("sticker")) do
        local damage = sticker.damage_per_tick
        if damage ~= nil then
            mtm.append(lu.damage_type_to_sources, {damage.type}, {
                start_type = "entity",
                start_name = sticker.name,
                damage = damage,
                edge_desc = "sticker-does-damage",
            })
        end
    end
    
    -- Impact damage
    -- Technically, locomotives also do impact damage, but they need rails and in general doesn't seem like it should count
    for _, car in pairs(prots("car")) do
        mtm.append(lu.damage_type_to_sources, {"impact"}, {
            start_type = "entity-operate",
            start_name = car.name,
            -- damage is indeterminate
            edge_desc = "impact-does-damage",
        })
    end
end

-- Groups of damage types that an entity is completely resistant to
-- Resistance is simply determined by whether the resistance percentage parameter is >= 100%
-- Format:
--   entity_name --> resistance_group_name
-- Also defines resistance groups to the damage types they correspond to (resistance_group_to_damage_types)
-- Format:
--   resistance_group_name --> damage_type --> true | nil
stage.entity_to_resistance_group = function()
    local lu = LookupLib.lookup

    lu.entity_to_resistance_group = {}
    lu.resistance_group_to_damage_types = {}

    for _, entity in pairs(base_prots("entity")) do
        if not categories.without_health[entity.name] then
            local resistances = {}
            for _, resistance in pairs(tablize(entity.resistances)) do
                if resistance.percent or 0 >= 100 then
                    table.insert(resistances, resistance.type)
                end
            end

            table.sort(resistances)
            local resistances_key = concat(resistances)
            lu.entity_to_resistance_group[entity.name] = resistances_key
            mtm.insert(lu.resistance_group_to_damage_types, {resistances_key}, resistances)
        end
    end
end

return stage