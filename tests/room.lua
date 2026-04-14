local key = DataRawLib.key.key

local lu = LookupLib.lookup

local function test_shattered_edge_has_promethium()
    local prom_ast = key("entity", "huge-promethium-asteroid")
    local loc = key("space-connection", "solar-system-edge-shattered-planet")


    log(serpent.block(lu.space_places))
    log(serpent.block(lu.asteroid_to_places[prom_ast]))


    assert(lu.asteroid_to_places[prom_ast][loc] == true)
end
test_shattered_edge_has_promethium()