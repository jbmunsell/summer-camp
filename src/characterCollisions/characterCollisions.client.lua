--
--	Jackson Munsell
--	14 Nov 2020
--	characterCollisions.client.lua
--
--	Character collisions client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local localCharacterGroupId = env.src.characterCollisions.net.GetLocalCharacterGroupId:InvokeServer()

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Set character group
local function setPartGroup(part)
	print("Set part group client")
	part.CollisionGroupId = localCharacterGroupId
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Set collision group on character added
rx.Observable.from(env.src.characterCollisions.net.CollisionGroupSet)
	:filter()
	:subscribe(setPartGroup)
