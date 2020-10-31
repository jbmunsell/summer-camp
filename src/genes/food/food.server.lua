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
local genes = env.src.genes
local interact = genes.interact
local pickup = genes.pickup
local food = genes.food

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local pickupUtil = require(pickup.util)
local genesUtil = require(genes.util)
local interactUtil = require(interact.util)
local foodUtil = require(food.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- All foods forever
local foodStream = genesUtil.initGene(food)

-- Set equip override
foodStream
	:map(dart.drag(foodUtil.equip))
	:subscribe(pickupUtil.setEquipOverride)

-- Create locks
foodStream
	:map(dart.drag("foodServer", "foodClient"))
	:subscribe(interactUtil.createLocks)

-- Set food server lock based on whether or not the food instance has a tray that has a holder
foodStream
	:flatMap(function (foodInstance)
		return rx.Observable.from(foodInstance.state.food.tray)
			:switchMap(function (tray)
				return tray and rx.Observable.from(tray.state.pickup.holder):map(dart.boolify)
				or rx.Observable.just(false)
			end)
			:map(dart.carry(foodInstance, "foodServer"))
	end)
	:subscribe(interactUtil.setLockEnabled)

-- Food activated
pickupUtil.getActivatedStream(food)
	:map(dart.omitFirst)
	:reject(foodUtil.isFoodEaten)
	:subscribe(foodUtil.eatFood)
