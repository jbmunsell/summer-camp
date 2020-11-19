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

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local fireplaceUtil = require(genes.fireplace.util)
local marshmallowUtil = require(genes.marshmallow.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Init gene
genesUtil.initGene(genes.marshmallow)

-- Render when their fire time changes
local fireTimeChanged = genesUtil.observeStateValue(genes.marshmallow, "fireTime")
fireTimeChanged
	:filter(function (instance, fireTime)
		return fireTime > instance.config.marshmallow.fireTimeMax.Value
		and not instance.state.marshmallow.destroyed.Value
	end)
	:subscribe(marshmallowUtil.destroyMarshmallow)
fireTimeChanged:subscribe(marshmallowUtil.updateMarshmallowStage)

-- When the stage changes, render
genesUtil.observeStateValue(genes.marshmallow, "stage"):subscribe(marshmallowUtil.renderMarshmallowStage)

-- Increase fire time for all marshmallows that are either burning or near fire
local instances = genesUtil.getInstances(genes.marshmallow):raw()
local int = 0.2
rx.Observable.interval(int):map(dart.constant(int)):subscribe(function (dt)
	for _, instance in pairs(instances) do
		if instance:IsDescendantOf(workspace) then
			local state = instance.state.marshmallow
			local config = instance.config.marshmallow
			local fireTime = state.fireTime
			local fire = fireplaceUtil.getFireWithinRadius(instance, "cookRadius")
			if fire or (fireTime.Value >= config.stages.burnt.time.Value) then
				fireTime.Value = fireTime.Value + dt
			end
		end
	end
end)
