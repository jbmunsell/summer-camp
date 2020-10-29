--
--	Jackson Munsell
--	04 Sep 2020
--	interact.server.lua
--
--	Server interact functionality
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local interact = env.src.interact
local objects = env.src.objects

-- modules
local objectsUtil = require(objects.util)

-- Init all interactables
objectsUtil.initObjectClass(interact)
