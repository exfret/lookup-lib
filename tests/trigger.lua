local key = DataRawLib.key.key
local traversal = DataRawLib.traversal
local prots = traversal.prots

local lu = LookupLib.lookup

log("Test: trigger")

-- Check that lu.triggers[lu.stop_to_triggers[stop][edge_desc][ind] has correct stop_type, stop_name
local function test_stop_to_triggers_has_consistent_stops()
    for stop, inds in pairs(lu.stop_to_triggers) do
        for ind, _ in pairs(inds) do
            local dec_struct = lu.triggers[ind]
            assert(key(dec_struct.stop_type, dec_struct.stop_name) == stop)
        end
    end
end
test_stop_to_triggers_has_consistent_stops()

local function test_asteroid_chunks_have_creating_trigger()
    for _, chunk in pairs(prots("asteroid-chunk")) do
        if chunk.name ~= "asteroid-chunk-unknown" and string.find(chunk.name, "parameter") == nil then
            assert(lu.stop_to_triggers[key("asteroid-chunk", chunk.name)] ~= nil)
        end
    end
end
test_asteroid_chunks_have_creating_trigger()

local function test_explosion_gunshot_added()
    local stop = key("entity", "explosion-gunshot")
    assert(next(lu.stop_to_triggers[stop]) ~= nil)
end
test_explosion_gunshot_added()