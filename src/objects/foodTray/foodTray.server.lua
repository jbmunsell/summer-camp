--
--	Jackson Munsell
--	19 Oct 2020
--	foodTray.server.lua
--
--	Food tray server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local objects = env.src.objects
local foodTray = objects.foodTray

-- modules
local objectsUtil  = require(objects.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Bind all trays
objectsUtil.initObjectClass(foodTray)
