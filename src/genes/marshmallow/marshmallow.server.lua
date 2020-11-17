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
local genesUtil = require(genes.util)
local fireplaceUtil = require(genes.fireplace.util)
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
genesUtil.observeStateValue(marshmallow, "stage"):subscribe(marshmallowUtil.renderMarshmallowStage)

-- Increase fire time for all marshmallows that are either burning or near fire
genesUtil.getInstanceStream(marshmallow):subscribe(function (instance)
	rx.Observable.fromProperty(instance, "Position"):subscribe(function ()
		local fire = fireplaceUtil.getFireWithinRadius(instance, "cookRadius")
		local isCooking = instance.state.marshmallow.isCooking
		if fire then
			isCooking.Value = true
		else
			local config = instance.config.marshmallow
			local fireTime = instance.state.marshmallow.fireTime
			local isBurning = (fireTime.Value >= config.stages.burnt.time.Value)
			isCooking.Value = isBurning
		end
	end)
end)
rx.Observable.heartbeat():subscribe(function (dt)
	for _, instance in pairs(genesUtil.getInstances(marshmallow):raw()) do
		local state = instance.state.marshmallow
		if state.isCooking.Value then
			local fireTime = state.fireTime
			fireTime.Value = fireTime.Value + dt
		end
	end
end)
