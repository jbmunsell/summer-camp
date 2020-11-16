--
--	Jackson Munsell
--	24 Oct 2020
--	dish.client.lua
--
--	Dish object client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local multiswitch = genes.multiswitch
local pickup = genes.pickup
local dish = genes.dish
local foodTray = genes.foodTray

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local pickupUtil = require(pickup.util)
local multiswitchUtil = require(multiswitch.util)
local genesUtil = require(genes.util)
local dishUtil = require(dish.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Set lock enabled factory function
local function setSwitchEnabled(enabled)
	return function (dishInstance)
		multiswitchUtil.setSwitchEnabled(dishInstance, "interact", "dish", enabled)
	end
end

-- Update dish locks
local function updateFoodSwitches()
	-- First, go ahead and unlock everything. Then we'll only lock what should be locked
	local allDishes = genesUtil.getInstances(dish)
	allDishes:foreach(setSwitchEnabled(true))

	-- Get tray that local player is holding
	local tray = env.LocalPlayer.Character
		and pickupUtil.getCharacterHeldObjects(env.LocalPlayer.Character)
			:first(dart.follow(genesUtil.hasGeneTag, foodTray))

	-- If there's no tray then don't lock anything
	if not tray then return end

	-- Functions
	local function isOnTray(dishInstance)
		return dishInstance.state.dish.tray.Value == tray
	end
	local function lockDishType(dishType)
		allDishes:filter(function (f) return dishUtil.getDishType(f) == dishType end)
			:foreach(setSwitchEnabled(false))
	end

	-- Lock dish of the same type that we have on our tray
	allDishes
		:filter(isOnTray)
		:map(dishUtil.getDishType)
		:foreach(lockDishType)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- All foods forever
local dishStream = genesUtil.initGene(dish)
local foodTrayStream = genesUtil.getInstanceStream(foodTray)

-- When any dish becomes attached to this local player's tray, lock all
-- 	other dish objects of that type
local foodTrayValueStream = dishStream
	:flatMap(function (foodInstance)
		return rx.Observable.from(foodInstance.state.dish.tray)
			:merge(rx.Observable.fromInstanceLeftGame(foodInstance))
	end)

local trayHolderValueStream = foodTrayStream
	:flatMap(function (tray)
		return rx.Observable.from(tray.state.pickup.holder)
			:merge(rx.Observable.fromInstanceLeftGame(tray))
	end)

foodTrayValueStream:merge(trayHolderValueStream)
	:throttle(0.1) -- Nice lil throttle to prevent an assload of events hitting at once
	:subscribe(updateFoodSwitches)
