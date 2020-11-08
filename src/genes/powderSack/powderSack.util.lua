--
--	Jackson Munsell
--	07 Nov 2020
--	powderSack.util.lua
--
--	powderSack gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local fireplace = genes.fireplace
local multiswitch = genes.multiswitch

-- modules
local fx = require(axis.lib.fx)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local fireplaceUtil = require(fireplace.util)
local multiswitchUtil = require(multiswitch.util)

-- lib
local powderSackUtil = {}

-- Set hot
function powderSackUtil.isPoofed(instance)
	return instance.state.powderSack.poofed.Value
end
function powderSackUtil.setPoofed(instance, poofed)
	instance.state.powderSack.poofed.Value = poofed
end

-- Get nearest fire to a powder sack instance
function powderSackUtil.getNearestFire(instance)
	return genesUtil.getInstances(fireplace)
		:filter(function (fireplaceInstance)
			return fireplaceInstance.state.fireplace.enabled.Value
		end)
		:min(function (fireplaceInstance)
			local dist = (axisUtil.getPosition(fireplaceInstance) - axisUtil.getPosition(instance)).magnitude
			return (dist <= fireplaceInstance.config.fireplace.powderAffectRadius.Value and dist)
		end)
end

-- Render color
function powderSackUtil.renderColor(instance)
	local color = instance.config.powderSack.color.Value
	instance.Sack.Color = color
	instance.Sack.PoofEmitter.Color = ColorSequence.new(color)
	instance.config.pickup.buttonColor.Value = color
end

-- Poof sack in fire
function powderSackUtil.poofSackInFire(sackInstance, fireplaceInstance)
	-- Set poofed, hide, and set fire color
	powderSackUtil.setPoofed(sackInstance, true)
	fireplaceUtil.setFireColor(fireplaceInstance, sackInstance.config.powderSack.color.Value)
	fx.hide(sackInstance)
	fx.smoothDestroy(sackInstance)
	multiswitchUtil.setSwitchEnabled(sackInstance, "interact", "destroyed", false)

	-- Emit particles from both objects
	local sackEmitter = sackInstance:FindFirstChild("PoofEmitter", true)
	sackEmitter:Emit(sackInstance.config.powderSack.firePoofParticleCount.Value)
end

-- return lib
return powderSackUtil
