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
genesUtil.initGene(marshmallow)

-- Render when their fire time changes
local fireTimeChanged = genesUtil.observeStateValue(marshmallow, "fireTime")
fireTimeChanged
	:filter(function (instance, fireTime)
		return fireTime > instance.config.marshmallow.fireTimeMax.Value
		and not instance.state.marshmallow.destroyed.Value
	end)
	:subscribe(marshmallowUtil.destroyMarshmallow)
fireTimeChanged:subscribe(marshmallowUtil.updateMarshmallowStage)

-- When the stage changes, render
genesUtil.observeStateValue(marshmallow, "stage")
	:subscribe(marshmallowUtil.renderMarshmallowStage)

-- Increase fire time for all marshmallows that are either burning or near fire
rx.Observable.heartbeat()
	:flatMap(function (dt)
		return rx.Observable.from(genesUtil.getInstances(marshmallow):raw())
			:map(dart.drag(dt))
	end)
	:filter(function (instance)
		local config = instance.config.marshmallow
		local fireTime = instance.state.marshmallow.fireTime.Value / config.fireTimeMax.Value
		return fireTime >= config.stages.burnt.time.Value
		or marshmallowUtil.getFireProximity(instance) <= config.cookDistanceThreshold.Value
	end)
	:subscribe(marshmallowUtil.increaseFireTime)
