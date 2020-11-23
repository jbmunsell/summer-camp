--
--	Jackson Munsell
--	07 Nov 2020
--	powderSack.util.lua
--
--	powderSack gene util
--

-- env
local AnalyticsService = game:GetService("AnalyticsService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local fireplace = genes.fireplace
local multiswitch = genes.multiswitch

-- modules
local fx = require(axis.lib.fx)
local soundUtil = require(axis.lib.soundUtil)
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

-- Poof sack in fire
function powderSackUtil.poofSackInFire(sackInstance, fireplaceInstance)
	-- Set poofed, hide, and set fire color
	local color = sackInstance.state.color.color.Value
	powderSackUtil.setPoofed(sackInstance, true)
	fireplaceUtil.setFireColor(fireplaceInstance, color)
	fx.hide(sackInstance)
	fx.smoothDestroy(sackInstance)
	multiswitchUtil.setSwitchEnabled(sackInstance, "interact", "destroyed", false)

	-- Emit particles from both objects
	local sackEmitter = sackInstance:FindFirstChild("PoofEmitter", true)
	sackEmitter:Emit(sackInstance.config.powderSack.firePoofParticleCount.Value)

	-- Play sound
	soundUtil.playSound(env.res.genes.powderSack.sounds.Poof, fireplaceInstance.PrimaryPart)

	-- Fire event
	AnalyticsService:FireEvent("powderSackPoofedInFire", {
		color = { color.R, color.G, color.B },
	})
end

-- return lib
return powderSackUtil
