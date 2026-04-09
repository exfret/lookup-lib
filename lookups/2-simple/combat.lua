-- START repeated header
-- Maintenance-wise, it's easiest to keep this exact header for all stage 2 lookups, even if not all these are used

local collision_mask_util = require("__core__/lualib/collision-mask-util")
local categories = DataRawLib.categories
local key = DataRawLib.key.key
local concat = DataRawLib.key.concat
local base_prots = DataRawLib.traversal.base_prots
local prots = DataRawLib.traversal.prots
local tablize = DataRawLib.traversal.tablize
local trigger_lib = DataRawLib.trigger

local stage = {}

-- END repeated header

-- Maps damage types to sources that can deal that damage type
-- Format:
--   damage_type_name --> prot_key --> tbl_of_damage_vals
stage.damage_type_sources = function()
    local lu = LookupLib.lookup

    lu.damage_type_sources = {}
    for _, damage_type in pairs(prots("damage-type")) do
        lu.damage_type_sources[damage_type.name] = {}
    end

    local function add_to_damage_type_sources(source_key, structs)
        local filtered_structs = trigger_lib.create_filters(structs)
        for _, damage_struct in pairs(filtered_structs.damage) do
            local damage_type_source = lu.damage_type_sources[damage_struct.damage.type]
            damage_type_source[source_key] = damage_type_source[source_key] or {}
            table.insert(damage_type_source[source_key], damage_struct.damage.amount)
        end
    end

    -- 1. AMMO ITEMS
    for _, ammo in pairs(prots("ammo")) do
        local structs = {}
        trigger_lib.flatten_structs_item(tablize(ammo.ammo_type.action), structs, "")
        local ammo_source_key = key("item", ammo.name)
        add_to_damage_type_sources(ammo_source_key, structs)
    end

    -- 2. TURRETS WITH BUILT-IN DAMAGE
    for _, turret_class in pairs({"electric-turret", "fluid-turret", "turret"}) do
        for _, turret in pairs(prots(turret_class)) do
            local structs = {}
            -- Ammo type is required for these turret classes
            trigger_lib.flatten_structs_item(tablize(turret.attack_parameters.ammo_type.action), structs, "")
            local turret_source_key = key("entity", turret.name)
            add_to_damage_type_sources(turret_source_key, structs)
        end
    end

    -- 3. COMBAT ROBOTS
    for _, robot in pairs(prots("combat-robot")) do
        local structs = {}
        trigger_lib.flatten_structs_item(tablize(tablize(robot.attack_parameters.ammo_type).action), structs, "")
        local robot_source_key = key("entity", robot.name)
        add_to_damage_type_sources(robot_source_key, structs)
    end

    -- 4. EQUIPMENT WITH ATTACK
    -- Out of all equipment, active-defense-equipment is the only one that could do damage
    for _, equipment in pairs(prots("active-defense-equipment")) do
        local structs = {}
        trigger_lib.flatten_structs_item(tablize(tablize(equipment.attack_parameters.ammo_type).action), structs, "")
        local equipment_source_key = key("equipment", equipment.name)
        add_to_damage_type_sources(equipment_source_key, structs)
    end
end

return stage