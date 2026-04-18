-- Runs between stages 1a and 2
-- Gathers all trigger structs and assigns how automated they are, what they require to activate, what effects they lead to, etc.
-- This often involves explicit node names ("entity-kill") needed for DepGraph, which are usually avoided

local categories = DataRawLib.categories
local extract = DataRawLib.extract
local key = DataRawLib.key.key
local mtm = DataRawLib.mtm
local traversal = DataRawLib.traversal
local base_prots = traversal.base_prots
local prots = traversal.prots
local listify = traversal.listify
local tablize = traversal.tablize
local trigger_lib = DataRawLib.trigger

local stage = {}

-- Format:
--   list of decorated structs
-- A decorated struct includes the following:
--   * struct: The original struct
--   * edge_desc: The edge descriptor
--   * start_type/start_name/stop_type/stop_name: The corresponding start/stop node types/names
-- Also included is a map lu.stop_to_triggers with format:
--   * stop --> ind of decorated struct --> true | nil
-- All edge_desc's are of the form "[source-type]-[description-involving-target-type]"
-- So, for example, we might have "item-ammo-does-damage"
-- Note that actual node keys are involved
-- Usually, I try to separate DepGraph things like node keys and lookups, but couldn't find a clean way around it in this case
stage.triggers = function()
    local lu = LookupLib.lookup

    lu.triggers = {}
    lu.stop_to_triggers = {}

    local function add_structs_to_triggers(structs, start_type, start_name, extra)
        local filtered_structs = trigger_lib.create_filters(structs)

        local function add_single_struct(struct, stop_type, stop_name, suffix)
            local stop_key = key(stop_type, stop_name)
            local edge_desc = start_type .. suffix
            table.insert(lu.triggers, {
                struct = struct,
                edge_desc = edge_desc,
                start_type = start_type,
                start_name = start_name,
                stop_type = stop_type,
                stop_name = stop_name,
                extra = extra,
            })
            mtm.insert(lu.stop_to_triggers, {stop_key, #lu.triggers})
        end

        for _, filtered_struct in pairs(filtered_structs.creates_asteroid_chunk) do
            add_single_struct(filtered_struct.struct, "asteroid-chunk", filtered_struct.chunk, "-creates-asteroid-chunk")
        end
        for _, filtered_struct in pairs(filtered_structs.creates_entity) do
            add_single_struct(filtered_struct.struct, "entity", filtered_struct.entity, "-creates-entity")
        end
        for _, filtered_struct in pairs(filtered_structs.damage) do
            add_single_struct(filtered_struct.struct, "damage-type", filtered_struct.damage.type, "-does-trigger-damage")
        end
    end

    -- Now, go by trigger
    -- This section could be made more concise but perhaps it's more readable when broken down so much per source?
    -- At the very least it helped me reason about each individual effect more

    -- Excludes:
    --  * Destroy cliffs capsule actions since that would require the player to have cliffs in their world, and we don't know that in data stage
    --  * Use on self capsule actions since they can't do damage to other sources, and I'm not sure how they act in other ways either
    --  * Gun attack parameters actions; their action does nothing and instead the engine uses the ammo's ammo_type
    --  * Robot destroy actions
    --  * Cargo pod impact actions
    --  * Entity created_effect, it could do something but doesn't in space age and would complicate logic to check for accurately
    --  * Explosion's explosion_effect, mostly just for secondary explosions and smoke (this is basically a delayed version of created_effect)
    --  * Fire's on_fuel_added_action, which again isn't used for much of consequence
    --  * Item destroyed_by_dropping_trigger and tile's default_destroyed_dropped_item_trigger
    --  * Lightning strike effect, since lightning can't be controlled by the player
    --  * Mining effects, like created_effect could do something but not really reliabel
    --  * Planet player effects, since those just apply to the player
    --  * Reactor meltdown effects, though it'd be funny to check for
    --  * Space platform starter pack trigger (what does this even do?)
    --  * Unit attack parameters (commented out), so I don't have to check for whether a unit is on the player's side (and it almost always isn't)

    -- Ammo ammo_type
    for _, ammo in pairs(prots("ammo")) do
        for _, ammo_type in pairs(listify(ammo.ammo_type)) do
            local structs = trigger_lib.flatten_structs_item(tablize(ammo_type.action))
            add_structs_to_triggers(structs, "item-ammo", ammo.name)
        end
    end
    
    -- Active defense aattack parameters
    for _, equipment in pairs(prots("active-defense-equipment")) do
        local structs = trigger_lib.flatten_structs_item(tablize(extract.attack_action(equipment)))
        add_structs_to_triggers(structs, "equipment-operate", equipment.name)
    end

    -- Combat robot attack parameters
    for _, robot in pairs(prots("combat-robot")) do
        local structs = trigger_lib.flatten_structs_item(tablize(extract.attack_action(robot)))
        -- Assume combat robots spawned are on player's side
        add_structs_to_triggers(structs, "entity", robot.name)
    end

    -- Unit attack parameters
    -- Most of these won't actually do anything for the player, but we can consider them for completeness
    -- Nevermind, I don't want special checks to see if an entity is on the player's "side" or not
    --[[for unit_class, _ in pairs(categories.units) do
        for _, unit in pairs(prots(unit_class)) do
            local structs = trigger_lib.flatten_structs_item(tablize(extract.attack_action(unit)))
            add_structs_to_triggers(structs, "entity-operate", unit.name)
            -- Revenge attack parameters
            if unit.class == "segmented-unit" then
                local structs2 = trigger_lib.flatten_structs_item(tablize(extract.attack_action(unit, {revenge = true})))
                add_structs_to_triggers(structs2, "entity-operate", unit.name)
            end
        end
    end]]

    -- Throw capsule action
    for _, capsule in pairs(prots("capsule")) do
        if capsule.capsule_action.type == "throw" then
            local structs = trigger_lib.flatten_structs_item(tablize(extract.attack_action(capsule.capsule_action)))
            add_structs_to_triggers(structs, "item-capsule", capsule.name)
        end
    end

    -- Turret attack parameters
    for turret_class, _ in pairs(categories.turrets) do
        -- Ammo turrets ignore their attack parameters and use their ammo's attack parameters instead
        if turret_class ~= "ammo-turret" then
            for _, turret in pairs(prots(turret_class)) do
                local structs = trigger_lib.flatten_structs_item(tablize(extract.attack_action(turret)))
                add_structs_to_triggers(structs, "entity-operate", turret.name)
            end
        end
    end

    -- Projectile actions
    -- We assume if a projectile is reachable, it was created/controlled by the player (i.e.- we don't check projectiles like worm spit (wait that's a stream not a projectile... you get the point))
    for projectile_class, _ in pairs(categories.projectiles) do
        for _, projectile in pairs(prots(projectile_class)) do
            local structs = trigger_lib.flatten_structs_item(tablize(projectile.action))
            add_structs_to_triggers(structs, "entity", projectile.name)
            -- Final action only triggers in very specific circumstances, so exclude it
        end
    end

    -- Beam action
    -- We assume if a beam is reachable, it was created/controlled by the player (i.e.- we don't check beams like cheeseman's death ray)
    for _, beam in pairs(prots("beam")) do
        local structs = trigger_lib.flatten_structs_item(tablize(beam.action))
        add_structs_to_triggers(structs, "entity", beam.name)
    end

    -- Prototype trigger actions
    -- We assume if an active trigger is reachable, it was created/controlled by the player (i.e.- we don't check trigger actions like... idk are there any examples in vanilla?)
    for trigger_class, _ in pairs(categories.triggers) do
        for _, trigger in pairs(prots(trigger_class)) do
            local structs = trigger_lib.flatten_structs_item(tablize(trigger.action))
            add_structs_to_triggers(structs, "trigger", trigger.name)
        end
    end

    -- Character tool attack result
    for _, character in pairs(prots("character")) do
        local structs = trigger_lib.flatten_structs_item(tablize(character.tool_attack_result))
        add_structs_to_triggers(structs, "entity-operate", character.name)
    end

    -- Fire on damage tick
    -- We assume if a fire is reachable, it was created/controlled by the player (i.e.- we don't check uh... explosive biter fires?)
    for _, fire in pairs(prots("fire")) do
        local structs = trigger_lib.flatten_structs_item(tablize(fire.on_damage_tick_effect))
        -- Since fires do damage to all sources, this technically doesn't need to be an "entity-operate", but this helps to ensure the fire is controlled by the player
        -- It wouldn't really be useful if a biter created the fire, since then the player can't aim it
        add_structs_to_triggers(structs, "entity", fire.name)
    end

    -- Fluid stream effects
    -- Both action and initial_action are used
    -- We assume if a stream is reachable, it was created/controlled by the player (i.e.- we don't check streams like worm spit)
    for _, stream in pairs(prots("stream")) do
        -- Like, fires, I suppose we could drop the "operate" requirement, but eh
        local structs = trigger_lib.flatten_structs_item(tablize(stream.action))
        add_structs_to_triggers(structs, "entity-operate", stream.name)
        local structs2 = trigger_lib.flatten_structs_item(tablize(stream.initial_action))
        add_structs_to_triggers(structs2, "entity-operate", stream.name)
    end

    -- Land mine effects
    for _, land_mine in pairs(prots("land-mine")) do
        local structs = trigger_lib.flatten_structs_item(tablize(land_mine.action))
        add_structs_to_triggers(structs, "entity-operate", land_mine.name)
    end

    -- Smoke with trigger effects
    -- Needed to detect, for example, poison cloud damage
    -- We assume if a smoke-with-trigger-effect is reachable, it was created/controlled by the player (i.e.- we don't count frozen biter cold clouds as reachable)
    for _, smoke in pairs(prots("smoke-with-trigger")) do
        local structs = trigger_lib.flatten_structs_item(tablize(smoke.action))
        add_structs_to_triggers(structs, "entity", smoke.name)
    end

    -- Spoiling triggers
    for _, item in pairs(base_prots("item")) do
        if item.spoil_to_trigger_result ~= nil then
            local structs = trigger_lib.flatten_structs_item(item.spoil_to_trigger_result.trigger)
            add_structs_to_triggers(structs, "item", item.name)
        end
    end

    -- Now take a breath, because we're about to do trigger effects! (yay...)

    -- Excludes:
    --  * Artillery flare stuff
    --  * Asteroid chunk dying_trigger_effect (corresponds to when it hits the platform)
    --  * Decorative trigger effects
    --  * Deliver impact combination (what does this even do?)
    --  * Entity damaged trigger effect (this one's on the edge, especially since I needed to do dying_trigger_effect, but ultimately decided against it)
    --  * Beam range_effects (mostly visual)
    --  * Particle trigger effects
    --  * Roboport door trigger effects
    --  * Rocket silo clamp/door trigger effect
    --  * Rolling stock drive over trigger effect
    --  * Spider leg trigger effects
    --  * Tile trigger effect (needs to be invoked by script)
    --  * Segmented unit update effects
    --  * Vehical crash effects

    -- Entity with health dying trigger effect (particularly relevant for asteroids)
    for _, entity in pairs(base_prots("entity")) do
        local structs = trigger_lib.flatten_structs_effect(tablize(entity.dying_trigger_effect))
        add_structs_to_triggers(structs, "entity-kill", "blop")--entity.name)
    end

    -- Delayed trigger effects; just do stickers
    -- We assume if a sticker is reachable, it was created/controlled by the player (i.e.- we don't count worm spit stickers as reachable)
    for _, sticker in pairs(prots("sticker")) do
        -- Technically, there might be more conditions for "can we apply this sticker" (also stickers are usually from enemies), but just do a basic check for now
        for _, update_effect in pairs(tablize(sticker.update_effects)) do
            local structs = trigger_lib.flatten_structs_effect(tablize(update_effect.effect))
            add_structs_to_triggers(structs, "entity", sticker.name)
        end
    end

    -- Oh that wasn't too bad!
end

return stage