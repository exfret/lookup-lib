-- This file also includes corresponding lookups for asteroid chunks since they are easier to group together with entity lookups

-- START repeated header
-- Maintenance-wise, it's easiest to keep this exact header for all stage 2 lookups, even if not all these are used

local collision_mask_util = require("__core__/lualib/collision-mask-util")
local categories = DataRawLib.categories
local extract = DataRawLib.extract
local key = DataRawLib.key.key
local concat = DataRawLib.key.concat
local base_prots = DataRawLib.traversal.base_prots
local prots = DataRawLib.traversal.prots
local tablize = DataRawLib.traversal.tablize
local trigger_lib = DataRawLib.trigger

local stage = {}

-- END repeated header

return stage