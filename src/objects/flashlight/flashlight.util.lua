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
	local v = (enabled and 0.7 or 0.2)
	instance.LightPart.Color = Color3.fromHSV(0, 0, v)
	instance.LightPart.Material = (enabled and Enum.Material.Neon or Enum.Material.SmoothPlastic)
end

-- Toggle light state
function flashlightUtil.toggleLightState(instance)
	instance.state.flashlight.enabled.Value = not instance.state.flashlight.enabled.Value
end

-- return lib
return flashlightUtil
