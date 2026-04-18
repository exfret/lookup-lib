local key = DataRawLib.key.key

local lu = LookupLib.lookup

log("Test: room")

local function test_shattered_edge_has_promethium()
    local prom_ast = key("entity", "huge-promethium-asteroid")
    local loc = key("space-connection", "solar-system-edge-shattered-planet")
    assert(lu.asteroid_to_places[prom_ast][loc] == true)
end
test_shattered_edge_has_promethium()