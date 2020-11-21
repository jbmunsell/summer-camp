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
local genes = env.src.genes
local net = env.src.characterCollisions.net

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function setPlayerPartGroup(player, part)
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
		return rx.Observable.fromInstanceEvent(c, "ChildAdded")
			:startWithTable(c:GetChildren())
			:reject(dart.follow(genesUtil.hasGeneTag, genes.pickup))
			:flatMap(function (instance)
				return rx.Observable.from(instance:GetDescendants())
					:startWith(instance)
			end)
			:filter(dart.isa("BasePart"))
			:map(dart.carry(p))
	end)
	:subscribe(setPlayerPartGroup)

-- Invoke callback
net.GetLocalCharacterGroupId.OnServerInvoke = getLocalCharacterGroupId
