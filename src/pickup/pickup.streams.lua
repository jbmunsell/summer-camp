--
--	Jackson Munsell
--	18 Oct 2020
--	pickupStreams.lua
--
--	Contains pickup-related streams, like managing player owned items.
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local pickup = env.src.pickup
local objects = env.src.objects

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local objectsUtil = require(objects.util)

---------------------------------------------------------------------------------------------------
-- Subjects
---------------------------------------------------------------------------------------------------

-- Behavior subject to represent all of our owned objects
local ownedObjects = rx.BehaviorSubject.new({})

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Handle owner changed
-- 	This function will appropriately add or remove objects according to their owner property
local function handleOwnerChanged(instance)
	local ownedList = ownedObjects:getValue()
	local hasInstance = table.find(ownedList, instance)
	local owns = (instance:IsDescendantOf(game) and instance.state.pickup.owner.Value == env.LocalPlayer)
	if owns then
		if not hasInstance then
			local newList = tableau.duplicate(ownedList)
			table.insert(newList, instance)
			ownedObjects:push(newList)
		end
	else
		if hasInstance then
			local newList = tableau.duplicate(ownedList)
			table.remove(newList, hasInstance)
			ownedObjects:push(newList)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Listen for tagged objects
objectsUtil.getObjectsStream(pickup)
	:flatMap(function (instance)
		return rx.Observable.from(instance.state.pickup.owner)
			:merge(rx.Observable.fromInstanceLeftGame(instance))
			:map(dart.constant(instance))
	end)
	:subscribe(handleOwnerChanged)

-- return lib
return {
	ownedObjects = ownedObjects,
}
