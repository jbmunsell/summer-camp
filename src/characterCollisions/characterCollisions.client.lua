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
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local localCharacterGroupId = env.src.characterCollisions.net.GetLocalCharacterGroupId:InvokeServer()
local defaultGroupId = 0

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Set character group
local function setPartGroup(part, groupId)
	part.CollisionGroupId = groupId
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Set collision group on character added
rx.Observable.from(env.src.characterCollisions.net.CollisionGroupSet)
	:filter()
	:map(dart.drag(localCharacterGroupId))
	:subscribe(setPartGroup)

-- Place local character held objects into collision group when they are picked up
genesUtil.getInstanceStream(genes.pickup):flatMap(function (instance)
	return rx.Observable.from(instance.state.pickup.holder)
		:merge(rx.Observable.fromInstanceLeftGame(instance):map(dart.constant(nil)))
		:replay(2)
		:skip(1)
		:map(function (oldHolder, newHolder)
			if oldHolder == env.LocalPlayer.Character then
				return defaultGroupId
			elseif newHolder == env.LocalPlayer.Character then
				return localCharacterGroupId
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

