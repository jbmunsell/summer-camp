--
--	Jackson Munsell
--	01 Nov 2020
--	marshmallow.server.lua
--
--	Marshmallow gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local marshmallow = genes.marshmallow

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local marshmallowUtil = require(marshmallow.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Init gene
local marshmallows = genesUtil.initGene(marshmallow)

-- Render when their fire time changes
local fireTimeChanged = marshmallows
	:flatMap(function (instance)
		return rx.Observable.from(instance.state.marshmallow.fireTime)
			:map(dart.carry(instance))
	end)
fireTimeChanged
	:filter(function (instance, fireTime)
		return fireTime > genesUtil.getConfig(instance).marshmallow.fireTimeMax
		and not instance.state.marshmallow.destroyed.Value
	end)
	:subscribe(marshmallowUtil.destroyMarshmallow)
fireTimeChanged
	:subscribe(marshmallowUtil.updateMarshmallowStage)

-- When the stage changes, render
marshmallows
	:flatMap(function (instance)
		return rx.Observable.from(instance.state.marshmallow.stage)
			:map(dart.constant(instance))
	end)
	:subscribe(marshmallowUtil.renderMarshmallow)

-- Increase fire time for all marshmallows that are either burning or near fire
rx.Observable.heartbeat()
	:flatMap(function (dt)
		return rx.Observable.from(genesUtil.getInstances(marshmallow):raw())
			:map(dart.drag(dt))
	end)
	:filter(function (instance)
		local config = genesUtil.getConfig(instance).marshmallow
		local fireTime = instance.state.marshmallow.fireTime.Value / config.fireTimeMax
		return fireTime >= config.stages.burnt.time
		or marshmallowUtil.getFireProximity(instance) <= config.cookDistanceThreshold
	end)
	:subscribe(marshmallowUtil.increaseFireTime)
