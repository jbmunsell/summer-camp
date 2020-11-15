--
--	Jackson Munsell
--	14 Nov 2020
--	characterCollisions.server.lua
--
--	Character collision group manager server driver
--

-- env
local PhysicsService = game:GetService("PhysicsService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local net = env.src.characterCollisions.net

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function setPlayerPartGroup(player, part)
	print("Set part group server")
	PhysicsService:SetPartCollisionGroup(part, "PlayerCharacters")
	rx.Observable.timer(1):subscribe(function ()
		net.CollisionGroupSet:FireClient(player, part)
	end)
end

local function getLocalCharacterGroupId()
	return PhysicsService:GetCollisionGroupId("LocalCharacter")
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Set character descendants
axisUtil.getPlayerCharacterStream()
	:flatMap(function (p, c)
		return rx.Observable.from(c.DescendantAdded)
			:startWithTable(c:GetDescendants())
			:filter(dart.isa("BasePart"))
			:map(dart.carry(p))
	end)
	:subscribe(setPlayerPartGroup)

-- Invoke callback
net.GetLocalCharacterGroupId.OnServerInvoke = getLocalCharacterGroupId
