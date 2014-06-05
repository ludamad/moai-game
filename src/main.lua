-------------------------------------------------------------------------------
-- Ensure undefined global access is an error.
-------------------------------------------------------------------------------

local global_meta = {}
setmetatable(_G, global_meta)

function global_meta:__index(k)
    error("Undefined global variable '" .. k .. "'!")
end

-------------------------------------------------------------------------------
-- Define global utilities.
-------------------------------------------------------------------------------

require "globals.misc"
require "globals.table"
require "globals.flextypes"
require "globals.string"

-------------------------------------------------------------------------------
-- Add citymode/ folder to require path.
-------------------------------------------------------------------------------

-- Hackish way to develop multiple games in the same repo, for now.
local GAME = "lanarts" -- "citymode"

package.path = package.path .. ';'..GAME..'/?.lua;src/'..GAME..'/?.lua'

-------------------------------------------------------------------------------
-- Ensure proper loading of moonscript files.
-------------------------------------------------------------------------------

require("moonscript.base").insert_loader()

-------------------------------------------------------------------------------
-- Finally, if we are not a debug server, run the game.
-------------------------------------------------------------------------------

local ErrorReporting = require "system.ErrorReporting"

--inspect()

local GIS = require "lanarts.GameInstSet" 

local gis = GIS.create(--[[width]] 100, --[[height]] 100)
local id = gis:add_instance( --[[x]] 32, --[[y]] 32, --[[radius]] 32, --[[target_radius]] 32, --[[solid]] true)

print("ID =", id)
--local module = os.getenv("f") or "game"
--ErrorReporting.wrap(function() 
--    require(module)
--end)()
