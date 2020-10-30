--
--	Jackson Munsell
--	29 Oct 2020
--	seat.server.lua
--
--	Seat server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local objects = env.src.objects
local seat = objects.seat

-- modules
local objectsUtil = require(objects.util)

---------------------------------------------------------------------------------------------------
-- Streams and subscriptions
---------------------------------------------------------------------------------------------------

-- Init seats to make them interactable
objectsUtil.initObjectClass(seat)
