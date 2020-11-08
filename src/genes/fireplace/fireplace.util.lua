--
--	Jackson Munsell
--	07 Nov 2020
--	fireplace.util.lua
--
--	fireplace gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)

-- lib
local fireplaceUtil = {}

-- Set fire color
function fireplaceUtil.setFireColor(instance, color)
	instance.state.fireplace.color.Value = color
end

-- Render fire
function fireplaceUtil.renderFireplaceEnabled(instance)
	fx.setFXEnabled(instance, instance.state.fireplace.enabled.Value)
	local spit = instance:FindFirstChild("SpittingEmbers", true)
	if spit then spit.Enabled = false end
end

-- Update fire color
function fireplaceUtil.renderFireColor(instance)
	local color = instance.state.fireplace.color.Value
	local descendants = tableau.from(instance:GetDescendants())
	descendants
		:filter(function (child)
			return child:IsA("Fire") or child:IsA("Light")
		end)
		:foreach(function (child)
			child.Color = color
		end)
	descendants
		:filter(dart.isa("ParticleEmitter"))
		:foreach(function (child)
			child.Color = ColorSequence.new(color)
		end)
	local fireplaceEmitter = instance:FindFirstChild("SpittingEmbers", true)
	if fireplaceEmitter then
		fireplaceEmitter:Emit(instance.config.fireplace.colorChangeParticleCount.Value)
	else
		warn("No SpittingEmbers emitter found in fireplace " .. instance:GetFullName())
	end
end

-- return lib
return fireplaceUtil
