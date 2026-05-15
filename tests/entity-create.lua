local key = DataRawLib.key.key

local lu = LookupLib.lookup

log("Test: entity-create")

local function test_yumako_tree_tiles_only_on_gleba()
    local yumako_tree = data.raw.plant["yumako-tree"]
    local tiles = lu.entity_buildability_tiles[yumako_tree.name]
    assert(tiles ~= nil)
    assert(next(tiles) ~= nil)
    for tile_name, _ in pairs(tiles) do
        local planets = lu.autoplaceable_to_planets[key("tile", tile_name)]
        -- This might be artificial soil, which isn't autoplaced
        if planets ~= nil then
            -- Check that tile is placeable on gleba, and only on gleba
            assert(planets["gleba"] == true)
            for planet, _ in pairs(planets) do
                assert(planet == "gleba")
            end
        end
    end
end
test_yumako_tree_tiles_only_on_gleba()