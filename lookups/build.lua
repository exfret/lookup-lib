LookupLib.ordered_filenames = {}

table.insert(LookupLib.ordered_filenames, "lookups.1a-raw")
table.insert(LookupLib.ordered_filenames, "lookups.1b-trigger")
local second_stage_names = {
    "combat",
    "entity-create",
    "entity-property",
    "equipment",
    "fuel",
    "item",
    "mining",
    "recipe",
    "room",
    "science",
    "tile",
}
for _, name in pairs(second_stage_names) do
    table.insert(LookupLib.ordered_filenames, "lookups.2-simple." .. name)
end
table.insert(LookupLib.ordered_filenames, "lookups.3-compound")
table.insert(LookupLib.ordered_filenames, "lookups.4-weight")

LookupLib.stages = {}
for _, filename in pairs(LookupLib.ordered_filenames) do
    table.insert(LookupLib.stages, require(filename))
end

LookupLib.build = function()
    LookupLib.lookup = {}

    for _, stage in pairs(LookupLib.stages) do
        for _, lookup in pairs(stage) do
            lookup()
        end
    end
end