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
local genes = env.src.genes

-- modules
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)

-- lib
local fireplaceUtil = {}

-- Set fire color
function fireplaceUtil.setFireColor(instance, color)
	instance.state.fireplace.color.Value = color
end

-- Get fire within radius
function fireplaceUtil.getFireWithinRadius(instance, radiusProperty)
	for _, fire in pairs(genesUtil.getInstances(genes.fireplace):raw()) do
		if fire.state.fireplace.enabled.Value then
			local dist = axisUtil.squareMagnitude(axisUtil.getPosition(fire) - axisUtil.getPosition(instance))
			if dist <= math.pow(fire.config.fireplace[radiusProperty].Value, 2) then
				return fire
			end
		end
	end
end

-- Render fire
function fireplaceUtil.renderFireplaceEnabled(instance)
	fx.setFXEnabled(instance, instance.state.fireplace.enabled.Value)
	local spit = instance:FindFirstChild("SpittingEmbers", true)
	if spit then spit.Enabled = false end
end

-- Update fire color
function fireplaceUtil.renderFireColor(instance, init)
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

	-- Show spitting embers if not init render
	if not init then
		local fireplaceEmitter = instance:FindFirstChild("SpittingEmbers", true)
		if fireplaceEmitter then
			fireplaceEmitter:Emit(instance.config.fireplace.colorChangeParticleCount.Value)
		else
			warn("No SpittingEmbers emitter found in fireplace " .. instance:GetFullName())
		end
	end
end

-- return lib
return fireplaceUtil
