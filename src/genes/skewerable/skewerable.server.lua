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
local interact = genes.interact
local skewer = genes.skewer
local skewerable = genes.skewerable

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local genesUtil = require(genes.util)
local pickupUtil = require(pickup.util)
local interactUtil = require(interact.util)
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

-- Create locks
skewerables:map(dart.drag("skewerableServer", "skewerableClient"))
	:subscribe(interactUtil.createLocks)

-- Set server lock according to whether we have a skewer AND that skewer has a holder
skewerables
	:flatMap(function (instance)
		return rx.Observable.from(instance.state.skewerable.skewer)
			:switchMap(function (skewerInstance)
				return skewerInstance
				and rx.Observable.from(skewerInstance.state.pickup.holder)
				or rx.Observable.just(false)
			end)
			:map(dart.boolify)
			:map(dart.carry(instance, "skewerableServer"))
	end)
	:subscribe(interactUtil.setLockEnabled)

-- When a skewerable changes slot index, bump down others and render weld accordingly
local stateChanged = skewerables
	:flatMap(function (instance)
		local state = instance.state.skewerable
		return rx.Observable.from(state.skewerSlotIndex)
			:filter(function () return state.skewer.Value end)
			:map(dart.constant(instance))
	end)
stateChanged
	:map(function (instance)
		local slotIndex = instance.state.skewerable.skewerSlotIndex.Value
		if slotIndex == 0 then
			return instance
		else
			return tableau.from(skewerUtil.getSkewered(instance.state.skewerable.skewer.Value))
				:reject(dart.equals(instance))
				:first(function (v)
					return v.state.skewerable.skewerSlotIndex.Value == slotIndex
				end)
		end
	end)
	:filter()
	:subscribe(skewerableUtil.bumpSlotIndex)
stateChanged
	:reject(function (instance) return instance.state.skewerable.skewerSlotIndex.Value == 0 end)
	:subscribe(skewerableUtil.renderSlotWeld)
