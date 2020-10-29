--
--	Jackson Munsell
--	28 Oct 2020
--	flashlight.util.lua
--
--	Flashlight object util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local fx = require(axis.lib.fx)

-- lib
local flashlightUtil = {}

-- Render flashlight
function flashlightUtil.renderFlashlight(instance)
	local enabled = instance.state.flashlight.enabled.Value
	fx.setFXEnabled(instance, enabled)
	if not enabled then
		fx.clearEmitters(instance)
	else
		instance.Dust:FindFirstChildWhichIsA("ParticleEmitter"):Emit(10)
	end
	instance.LightPart.Transparency = (enabled and 0 or 0.9)
end

-- Toggle light state
function flashlightUtil.toggleLightState(instance)
	instance.state.flashlight.enabled.Value = not instance.state.flashlight.enabled.Value
end

-- return lib
return flashlightUtil
