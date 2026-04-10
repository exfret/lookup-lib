require("tests.general")

-- For the remaining tests, the lookups table won't/shouldn't be reloaded/modified, so that we can just do a load here
LookupLib.build()

require("tests.combat")