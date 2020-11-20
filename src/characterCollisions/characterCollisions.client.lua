--
--	Jackson Munsell
--	14 Nov 2020
--	characterCollisions.client.lua
--
--	Character collisions client driver
--

-- env
local PhysicsService = game:GetService("PhysicsService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Set character group
local function setPartGroup(part, groupName)
	PhysicsService:SetPartCollisionGroup(part, groupName)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Set collision group on character added
rx.Observable.from(env.src.characterCollisions.net.CollisionGroupSet)
	:filter()
	:map(dart.drag("LocalCharacter"))
	:subscribe(setPartGroup)

-- Place local character held objects into collision group when they are picked up
genesUtil.getInstanceStream(genes.pickup):flatMap(function (instance)
	return rx.Observable.from(instance.state.pickup.holder)
		:merge(rx.Observable.fromInstanceLeftGame(instance):map(dart.constant(nil)))
		:replay(2)
		:skip(1)
		:map(function (oldHolder, newHolder)
			if oldHolder == env.LocalPlayer.Character then
				return "Default"
			elseif newHolder == env.LocalPlayer.Character then
				return "LocalCharacter"
			else
				return nil
			end
		end)
		:filter()
		:flatMap(function (groupId)
			return rx.Observable.from(instance:GetDescendants())
				:startWith(instance)
				:filter(dart.isa("BasePart"))
				:map(dart.drag(groupId))
		end)
end):subscribe(setPartGroup)

