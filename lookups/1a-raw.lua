local key = DataRawLib.key.key
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

return stage