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

-- Maps damage types to sources that can deal that damage type
-- Format:
--   damage_type_name --> prot_key --> list of {amount = damage_amount, source = damage_source, reasonable = true | false}
-- "damage_source" is where the damage generally comes from, like ammo being shot or something weirder like a cargo pod hitting something
-- "reasonable" is whether this could be reasonably considered a source of damage for the player for logic reasons
-- This is used in DepGraphLib to filter out "unreasonable" sources of damage *cough* cargo pods *cough*
-- "damage_source" can then be used for further filtering, especially for determining contexts (i.e.- what's not just possible, but also doable in an automated manner, etc.)
-- This lookup doesn't cover indirect damage (such as by creating a projectile that then does damage)
-- That is handled in DepGraphLib by using nodes for these projectiles, too
stage.damage_type_sources = function()
    local lu = LookupLib.lookup

    lu.damage_type_sources = {}
    for _, damage_type in pairs(prots("damage-type")) do
        lu.damage_type_sources[damage_type.name] = {}
    end

    is_reasonable = true
    local function add_to_damage_type_sources(source_type, source_key, structs)
        local filtered_structs = trigger_lib.create_filters(structs)
        for _, damage_struct in pairs(filtered_structs.damage) do
            local damage_type_source = lu.damage_type_sources[damage_struct.damage.type]
            damage_type_source[source_key] = damage_type_source[source_key] or {}
            table.insert(damage_type_source[source_key], {amount = damage_struct.damage.amount, source = source_type, reasonable = is_reasonable})
        end
    end

    -- 1. ammo
    -- Note that for turrets requiring ammo and guns, the damage is on the ammo instead
    -- In fact, the ammo_type for them seems to be completely ignored even if damage is put there
    -- Thus, we need to think of the ammo as the damage dealer and ask "can something shoot this ammo" rather than "is there ammo to operate this gun"
    for _, ammo in pairs(prots("ammo")) do
        local structs = {}
        trigger_lib.flatten_structs_item(tablize(ammo.ammo_type.action), structs, "")
        local ammo_source_key = key("item", ammo.name)
        add_to_damage_type_sources("ammo", ammo_source_key, structs)
    end

    -- 2. turret
    -- Only cover ones with in-built damage; ammo-turret ignores ammo_type even if it's set within attack_parameters and therefore cannot do damage on its own (see above)
    for _, turret_class in pairs({"electric-turret", "fluid-turret", "turret"}) do
        for _, turret in pairs(prots(turret_class)) do
            local structs = {}
            trigger_lib.flatten_structs_item(tablize(extract.attack_action(turret)), structs, "")
            local turret_source_key = key("entity", turret.name)
            add_to_damage_type_sources("turret", turret_source_key, structs)
        end
    end

    -- 3. capsule
    -- Only includes thrown capsules (i.e.- capsule_type.type == "throw")
    -- Capsules used on self could only damage other things by spawning something that did, which we already cover
    -- destroy-cliffs capsules could technically do damage too, but are separated out since they're a much more "unreasonable" source of damage
    -- For reference, destroy-cliffs capsules are almost the exact same as thrown ones, but must be aimed at cliffs (which becomes especially problematic if cliffs were turned off in map settings)
    for _, capsule in pairs(prots("capsule")) do
        if capsule.capsule_action == "throw" then
            local structs = {}
            trigger_lib.flatten_structs_item(tablize(extract.attack_action(capsule.capsule_action)), structs, "")
            local capsule_source_key = key("item", capsule.name)
            add_to_damage_type_sources("capsule", capsule_source_key, structs)
        end
    end

    -- 4. combat-robot
    for _, robot in pairs(prots("combat-robot")) do
        local structs = {}
        trigger_lib.flatten_structs_item(tablize(extract.attack_action(robot)), structs, "")
        local robot_source_key = key("entity", robot.name)
        add_to_damage_type_sources("combat-robot", robot_source_key, structs)
    end

    -- 5. equipment
    -- Out of all equipment, active-defense-equipment is the only one that can do damage
    for _, equipment in pairs(prots("active-defense-equipment")) do
        local structs = {}
        trigger_lib.flatten_structs_item(tablize(extract.attack_action(equipment)), structs, "")
        local equipment_source_key = key("equipment", equipment.name)
        add_to_damage_type_sources("equipment", equipment_source_key, structs)
    end

    -- 6. unit
    -- Under normal circumstances, the player doesn't have biter minions so this doesn't usually matter for graph construction
    -- If they did though, it would still be a "reasonable" source of damage, so it is here as such
    for _, unit_class in pairs({"unit", "segmented-unit", "spider-unit"}) do
        for _, unit in pairs(prots(unit_class)) do
            local structs = {}
            trigger_lib.flatten_structs_item(tablize(extract.attack_action(unit)), structs, "")
            local unit_source_key = key("entity", unit.name)
            add_to_damage_type_sources("unit", unit_source_key, structs)

            -- Get the special revenge_attack_parameters for segmented units
            if unit.type == "segmented-unit" then
                local revenge_structs = {}
                trigger_lib.flatten_structs_item(tablize(extract.attack_action(unit, {revenge = true})), revenge_structs, "")
                add_to_damage_type_sources("unit", unit_source_key, revenge_structs)
            end
        end
    end

    -- Now for things without attack_parameters
    -- Yes, the list keeps going

    -- 7. projectile
    -- Projectile's final_action is included separately as a more "unreasonable" source of damage
    for _, projectile_class in pairs({"projectile", "artillery-projectile"}) do
        for _, projectile in pairs(prots(projectile_class)) do
            local action_structs = {}
            trigger_lib.flatten_structs_item(tablize(projectile.action), action_structs, "")
            local projectile_key = key("entity", projectile.name)
            add_to_damage_type_sources("projectile", projectile_key, action_structs)
        end
    end

    -- 8. beam
    for _, beam in pairs(prots("beam")) do
        local structs = {}
        trigger_lib.flatten_structs_item(tablize(beam.action), structs, "")
        local beam_source_key = key("entity", beam.name)
        add_to_damage_type_sources("beam", beam_source_key, structs)
    end

    -- 9. trigger-prototype
    -- These are represented as their own nodes in the dependency graph
    for _, trigger_prototype_class in pairs({"chain-active-trigger", "delayed-active-trigger"}) do
        for _, trigger_prototype in pairs(prots(trigger_prototype_class)) do
            local structs = {}
            trigger_lib.flatten_structs_item(tablize(trigger_prototype.action), structs, "")
            local trigger_prototype_source_key = key("trigger", trigger_prototype.name)
            add_to_damage_type_sources("trigger-prototype", trigger_prototype_source_key, structs)
        end
    end

    -- 10. character
    -- This is the damage done by melee
    for _, character in pairs(prots("character")) do
        local structs = {}
        trigger_lib.flatten_structs_item(tablize(character.tool_attack_result), structs, "")
        local character_source_key = key("entity", character.name)
        add_to_damage_type_sources("character", character_source_key, structs)
    end

    -- 11. fire
    for _, fire in pairs(prots("fire")) do
        local structs = {}
        trigger_lib.flatten_structs_item(tablize(fire.on_damage_tick_effect), structs, "")
        local fire_source_key = key("entity", fire.name)
        add_to_damage_type_sources("fire", fire_source_key, structs)
    end

    -- 12. stream
    -- Includes worm acid spit and flamethrower flames
    -- Some use "initial_action" (only first particle has an effect, used by worm spit), and some use "action" (like flamethrowers)
    for _, stream in pairs(prots("stream")) do
        local stream_source_key = key("entity", stream.name)

        local structs = {}
        trigger_lib.flatten_structs_item(tablize(stream.action), structs, "")
        add_to_damage_type_sources("stream", stream_source_key, structs)

        local initial_structs = {}
        trigger_lib.flatten_structs_item(tablize(stream.initial_action), initial_structs, "")
        add_to_damage_type_sources("stream", stream_source_key, initial_structs)
    end

    -- TODO:
    --  * landmine
    --  * smoke (used with poison cloud)
    --  * direct trigger effect users (like dying_trigger_effect)
    --  * damage from impacts (note that the "impact" damage category is special)

    -- BEGIN "UNREASONABLE" DAMAGE SOURCES
    is_reasonable = false

    -- TODO:

    -- 1. cargo-pod

    -- 2. destroy-cliffs (call cliff-capsule)

    -- 3. created-effect
    -- Triggered when an entity is created, defined by an entity's "created_effect"
    -- This is used often in explosions, but explosions don't actually carry the damage, so none of the created effects I looked at included damage
    -- The damage seems to be on the effect creating the explosion, or things that are created together with it, so I'm going to assume damage on a created-effect is probably a mistake and thus can be counted as "unreasonable"
    -- This also saves effort when constructing the dependency graph to figure out what counts as "created"

    -- 4. explosion-effect
    -- Only used twice in all of data.raw, neither time with damage defined on it
    -- Again, damage should generally be defined on the effect creating the explosion, so any of it defined here is "unreasonable"

    -- 5. projectile-final-action
    -- Only triggered in specific circumstances
    -- These circumstances include the targeted entity dying, so direct damage defined here also does nothing; though area damage might have an effect
    -- However, I'm not going to test if it's area/direct/etc. since that's a bit silly; this won't be used in the dependency graph anyways

    -- 6. robot-expiring
    -- These are trigger items caused by a flying robot with limited timespan (combat or capture robot) reaching the end of its life
    -- Doesn't matter in vanilla, but technically if like a mod defines a robot to do damage when expiring (maybe justified by it crashing to the ground), then we should still sense that
    -- TODO: Apparently this is also defined for robots with logistic interface; they die when they run out of energy
    -- TODO: Also, I realized capture robots may not have a lifespan, so I wonder what triggers their destroy_action

    -- 7. lightning

    -- 8. mining-trigger

    -- 9. meltdown
    -- What happens when a reactor is destroyed large enough temperature

    -- 10. spoil
    -- A trigger raised when something spoils, possibly including damage/explosions etc.

    -- Not included:
    --  * non_colliding_fail_result on the create-entity trigger effects; even if it wasn't ridiculous to check these, they are covered by one of the flattenings already since they must be defined within a trigger effect
    --  * on_fuel_added_action on fire prototypes; it's not where the damage is normally defined anyways and I'm not sure enough of what it does
    --  * attack_parameters for capsule_actions not of type "throw" or "destroy-cliffs", since they either are remotes or could only possible damage the player anyways
    --  * destroyed_by_dropping_trigger on ItemPrototype because I'm not sure what it does and it does not sound like something that should be dealing damage
    --  * default_destroyed_dropped_item_trigger on TilePrototype for the same reason as the last
    --  * player_effects on PlanetPrototype's since they can only cause the player damage and going out of my way to see if it's possible for the player to die doesn't seem worth it
    --  * SpacePlatformStarterPackPrototype's trigger, because I only see that being something like a one time thing that's done when a platform is initially created and not even worth doing for the meme
end

return stage