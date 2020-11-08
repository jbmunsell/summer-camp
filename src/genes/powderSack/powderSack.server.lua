--
--	Jackson Munsell
--	07 Nov 2020
--	powderSack.server.lua
--
--	powderSack gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local throw = genes.throw
local powderSack = genes.powderSack

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local throwUtil = require(throw.util)
local powderSackUtil = require(powderSack.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local sacks = genesUtil.initGene(powderSack)

-- Render color on init
sacks:subscribe(powderSackUtil.renderColor)

-- Connect to sack thrown
-- throwUtil.getThrowStream(powderSack)
-- 	:map(dart.drag(true))
-- 	:subscribe(powderSackUtil.setHot)

-- Blow it when one gets close enough to a fire
rx.Observable.heartbeat()
	:flatMap(function ()
		return rx.Observable.from(genesUtil.getInstances(powderSack))
	end)
	:reject(powderSackUtil.isPoofed)
	:map(function (instance)
		return instance, powderSackUtil.getNearestFire(instance)
	end)
	:map(dart.drop(3))
	:filter(dart.boolAnd)
	:subscribe(powderSackUtil.poofSackInFire)
