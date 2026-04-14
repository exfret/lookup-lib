local key = DataRawLib.key.key
local base_prots = DataRawLib.traversal.base_prots
local prots = DataRawLib.traversal.prots

local stage = {}

-- Rooms are places that you can be (planets and surfaces)
-- Format:
--   room_key --> room
stage.rooms = function()
    local lu = LookupLib.lookup

    lu.rooms = {}
    for _, class in pairs({"planet", "surface"}) do
        for prot_name, prot in pairs(prots(class)) do
            lu.rooms[key(prot)] = {
                type = class,
                name = prot_name,
            }
        end
    end
end

-- Space places are places that a surface (the prototype) can be
-- Note that as a space place, a planet is a space-location node, not a room node
stage.space_places = function()
    local lu = LookupLib.lookup

    lu.space_places = {}

    for _, base_class in pairs({"space-location", "space-connection"}) do
        for _, loc in pairs(base_prots(base_class)) do
            lu.space_places[key(base_class, loc.name)] = {
                type = base_class,
                name = loc.name
            }
        end
    end
end

return stage