local concat = DataRawLib.key.concat
local prots = DataRawLib.traversal.prots

local lu = LookupLib.lookup

log("Test: combat")

-- Check that each damage type has something dealing that damage
-- This is easily untrue with mods, but the tests target space age vanilla anyways
local function test_all_damage_types_have_damage_dealer()
    for _, damage_type in pairs(prots("damage-type")) do
        local sources = lu.damage_type_sources[damage_type.name]
        assert(sources ~= nil)
        -- Assert it's not the empty table
        assert(next(sources) ~= nil)
    end
end
-- CRITICAL TODO: Impact damage not added yet!
--test_all_damage_types_have_damage_dealer()

-- Check that the entity resistance group for "electric" and "fire" resistance exists (should be added by huge asteroids)
local function test_entity_resistance_group_electric_fire_exists()
    local my_resistances = {"electric", "fire"}
    table.sort(my_resistances)
    assert(lu.resistance_group_to_damage_types[concat(my_resistances)] ~= nil)
end
test_entity_resistance_group_electric_fire_exists()