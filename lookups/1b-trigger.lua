-- Runs between stages 1a and 2
-- Gathers all trigger structs and assigns how automated they are, what they require to activate, what effects they lead to, etc.
-- This often involves explicit node names ("entity-kill") needed for DepGraph, which are usually avoided

local key = DataRawLib.key.key
local traversal = DataRawLib.traversal
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
--   * stop --> edge_desc --> ind of decorated struct --> true | nil
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

        local function add_single_struct(struct, suffix, stop_type, stop_name)
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
            lu.stop_to_triggers[stop_key] = lu.stop_to_triggers[stop_key] or {}
            lu.stop_to_triggers[stop_key][edge_desc] = lu.stop_to_triggers[stop_key][edge_desc] or {}
            lu.stop_to_triggers[stop_key][edge_desc][#lu.triggers] = true
        end

        for _, filtered_struct in pairs(filtered_structs.damage) do
            add_single_struct(filtered_struct.struct, "-does-trigger-damage", "damage-type", filtered_struct.damage.type)
        end
    end

    -- Now, go by trigger

    -- Ammo ammo_type
    for _, ammo in pairs(prots("ammo")) do
        for _, ammo_type in pairs(listify(ammo.ammo_type)) do
            local structs = trigger_lib.flatten_structs_item(tablize(ammo_type.action))
            add_structs_to_triggers(structs, "item-ammo", ammo.name)
        end
    end

    -- Active defense aattack parameters
    --for _, equipment in pairs(prots(""))
end

return stage