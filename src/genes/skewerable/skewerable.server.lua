--
--	Jackson Munsell
--	01 Nov 2020
--	skewerable.server.lua
--
--	skewerable gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local pickup = genes.pickup
local multiswitch = genes.multiswitch
local skewer = genes.skewer
local skewerable = genes.skewerable

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local genesUtil = require(genes.util)
local pickupUtil = require(pickup.util)
local multiswitchUtil = require(multiswitch.util)
local skewerUtil = require(skewer.util)
local skewerableUtil = require(skewerable.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local skewerables = genesUtil.initGene(skewerable)

-- Add pickup override
skewerables:map(dart.drag(skewerableUtil.equip))
	:subscribe(pickupUtil.setEquipOverride)

-- Set server lock according to whether we have a skewer AND that skewer has a holder
genesUtil.observeStateValue(skewerable, "skewer", function (o)
	return o:switchMap(function (_, skewerInstance)
		local isInteractable = skewerInstance
			and rx.Observable.from(skewerInstance.state.pickup.holder):map(dart.boolNot)
			or rx.Observable.just(true)
		return isInteractable
			:map(dart.carry("interact", "skewerable"))
	end)
end):subscribe(multiswitchUtil.setSwitchEnabled)

-- When a skewerable changes slot index, bump down others and render weld accordingly
local slotChanged = genesUtil.observeStateValue(skewerable, "skewerSlotIndex")
	:filter(genesUtil.getStateValue(skewerable, "skewer"))
	:map(dart.select(1))
slotChanged
	:map(function (instance)
		local slotIndex = instance.state.skewerable.skewerSlotIndex.Value
		if slotIndex == 0 then
			return instance
		else
			return tableau.from(skewerUtil.getSkewered(instance.state.skewerable.skewer.Value))
				:reject(dart.equals(instance))
				:first(genesUtil.stateValueEquals(skewerable, "skewerSlotIndex", slotIndex))
		end
	end)
	:filter()
	:subscribe(genesUtil.transformStateValue(skewerable, "skewerSlotIndex", dart.increment))
slotChanged
	:reject(genesUtil.stateValueEquals(skewerable, "skewerSlotIndex", 0))
	:subscribe(skewerableUtil.renderSlotWeld)
