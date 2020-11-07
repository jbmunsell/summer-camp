--
--	Jackson Munsell
--	24 Oct 2020
--	dish.server.lua
--
--	dish object server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local multiswitch = genes.multiswitch
local pickup = genes.pickup
local dish = genes.dish

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local pickupUtil = require(pickup.util)
local genesUtil = require(genes.util)
local multiswitchUtil = require(multiswitch.util)
local dishUtil = require(dish.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- All foods forever
local dishStream = genesUtil.initGene(dish)

-- Set equip override
dishStream
	:map(dart.drag(dishUtil.equip))
	:subscribe(pickupUtil.setEquipOverride)

-- Set dish server lock based on whether or not the dish instance has a tray that has a holder
dishStream
	:flatMap(function (foodInstance)
		return rx.Observable.from(foodInstance.state.dish.tray)
			:switchMap(function (tray)
				return tray and rx.Observable.from(tray.state.pickup.holder):map(dart.boolNot)
				or rx.Observable.just(true)
			end)
			:map(dart.carry(foodInstance, "interact", "dish"))
	end)
	:subscribe(multiswitchUtil.setSwitchEnabled)
