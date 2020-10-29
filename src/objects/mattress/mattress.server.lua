--
--	Jackson Munsell
--	11 Oct 2020
--	mattress.server.lua
--
--	Mattress server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local objects = env.src.objects
local mattress = objects.mattress

-- modules
local objectsUtil = require(objects.util)

---------------------------------------------------------------------------------------------------
-- Streams and subscriptions
---------------------------------------------------------------------------------------------------

-- Init mattresses to make them interactable
objectsUtil.initObjectClass(mattress)
