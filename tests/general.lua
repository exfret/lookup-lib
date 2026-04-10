-- Check that each lookup only modifies its corresponding lookup table
local function test_lookups_modify_only_their_table()
    for _, stage in pairs(LookupLib.stages) do
        for lookup_name, lookup in pairs(stage) do
            -- Load up to lookup_name
            LookupLib.lookup = {}
            for _, stage in pairs(LookupLib.stages) do
                for other_lookup_name, other_lookup in pairs(stage) do
                    if other_lookup_name == lookup_name then
                        break
                    end
                    other_lookup()
                end
            end
            
            local old_lookups = table.deepcopy(LookupLib.lookup)
            lookup()
            for other_lookup_name, other_lookup_value in pairs(LookupLib.lookup) do
                if lookup_name ~= other_lookup_name then
                    assert(table.compare(old_lookups[other_lookup_name], other_lookup_value))
                end
            end
        end
    end
end
test_lookups_modify_only_their_table()