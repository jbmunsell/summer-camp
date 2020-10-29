--
--	Jackson Munsell
--	24 Oct 2020
--	food.server.lua
--
--	Food object server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local objects = env.src.objects
local interact = objects.interact
local pickup = objects.pickup
local food = objects.food

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local pickupUtil = require(pickup.util)
local objectsUtil = require(objects.util)
local interactUtil = require(interact.util)
local foodUtil = require(food.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- init food object
local function initFood(foodInstance)
	-- Create pickup override and interact lock
	pickupUtil.setEquipOverride(foodInstance, foodUtil.equip)
	interactUtil.createLock(foodInstance, "food")
	interactUtil.createLock(foodInstance, "foodClient")

	-- Switch map tray holder value to lock and unlock interact
	rx.Observable.from(foodInstance.state.food.tray)
		:switchMap(function (tray)
			return tray
			and rx.Observable.from(tray.state.pickup.holder)
				:map(dart.boolify)
			or rx.Observable.just(false)
		end)
		:subscribe(dart.bind(interactUtil.setLockEnabled, foodInstance, "food"))
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- All foods forever
local foodStream = objectsUtil.initObjectClass(food)
foodStream:subscribe(initFood)
