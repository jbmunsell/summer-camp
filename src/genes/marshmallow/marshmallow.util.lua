--
--	Jackson Munsell
--	01 Nov 2020
--	marshmallow.util.lua
--
--	Marshmallow gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local fireplace = genes.fireplace

-- modules
local fx = require(axis.lib.fx)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)

-- lib
local marshmallowUtil = {}
local cookingStages = {
	"normal",
	"cooked",
	"burnt",
}

-- Get fire proximity
function marshmallowUtil.getFireProximity(instance)
	return genesUtil.getInstances(fireplace)
		:filter(function (fire) return fire.state.fireplace.enabled.Value end)
		:map(function (fire)
			return (axisUtil.getPosition(fire) - axisUtil.getPosition(instance)).magnitude
		end)
		:min() or math.huge
end

-- Is eaten
function marshmallowUtil.isEaten(instance)
	return instance.state.marshmallow.eaten.Value
end

-- Increase fire time
function marshmallowUtil.increaseFireTime(instance, dt)
	instance.state.marshmallow.fireTime.Value = instance.state.marshmallow.fireTime.Value + dt
end

-- Render marshmallow
function marshmallowUtil.updateMarshmallowStage(instance)
	-- We have to use long form accessing here because of metatable magic
	-- 	with config tables and folders
	local config = genesUtil.getConfig(instance).marshmallow
	local fireTime = instance.state.marshmallow.fireTime.Value / config.fireTimeMax
	local max = nil
	for _, stage in pairs(cookingStages) do
		if config.stages[stage].time <= fireTime
		and (not max or (config.stages[max].time < config.stages[stage].time))
		then
			max = stage
		end
	end
	instance.state.marshmallow.stage.Value = max
end

-- Render marshmallow
function marshmallowUtil.renderMarshmallow(instance)
	-- Set texture and size and enable fx if burnt
	local config = genesUtil.getConfig(instance).marshmallow
	local stageName = instance.state.marshmallow.stage.Value
	local stage = config.stages[stageName]
	instance.TextureID = stage.texture
	instance.Size = stage.size
	fx.setFXEnabled(instance, (stageName == "burnt"))
end

-- Destroy marshmallow
function marshmallowUtil.destroyMarshmallow(instance)
	instance.state.marshmallow.destroyed.Value = true
	fx.fadeOutAndDestroy(instance)
end

-- return lib
return marshmallowUtil
