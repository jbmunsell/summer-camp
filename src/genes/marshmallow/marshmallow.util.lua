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

-- modules
local fx = require(axis.lib.fx)

-- lib
local marshmallowUtil = {}

-- Increase fire time
function marshmallowUtil.increaseFireTime(instance, dt)
	instance.state.marshmallow.fireTime.Value = instance.state.marshmallow.fireTime.Value + dt
end

-- Render marshmallow
function marshmallowUtil.updateMarshmallowStage(instance)
	local config = instance.config.marshmallow
	local state = instance.state.marshmallow
	local fireTime = state.fireTime.Value / config.fireTimeMax.Value
	local max = nil
	for _, stage in pairs(config.stages:GetChildren()) do
		local t = stage.time.Value
		if t <= fireTime and (not max or (max.time.Value < t))
		then
			max = stage
		end
	end
	state.stage.Value = max.name
end

-- Render marshmallow
function marshmallowUtil.renderMarshmallowStage(instance)
	-- Set texture and size and enable fx if burnt
	local config = instance.config.marshmallow
	local stageName = instance.state.marshmallow.stage.Value
	local stage = config.stages[stageName]
	instance.TextureID = stage.texture.Value
	instance.Size = stage.size.Value
	fx.setFXEnabled(instance, (stageName == "burnt"))
end

-- Destroy marshmallow
function marshmallowUtil.destroyMarshmallow(instance)
	instance.state.marshmallow.destroyed.Value = true
	fx.fadeOutAndDestroy(instance)
end

-- return lib
return marshmallowUtil
