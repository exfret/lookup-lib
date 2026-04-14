local key = DataRawLib.key.key

local lu = LookupLib.lookup

-- Check that lu.triggers[lu.stop_to_triggers[stop][edge_desc][ind]
local function test_stop_to_triggers_has_consistent_stops()
    for stop, edge_to_inds in pairs(lu.stop_to_triggers) do
        for _, inds in pairs(edge_to_inds) do
            for ind, _ in pairs(inds) do
                local dec_struct = lu.triggers[ind]
                assert(key(dec_struct.stop_type, dec_struct.stop_name) == stop)
            end
        end
    end
end
test_stop_to_triggers_has_consistent_stops()