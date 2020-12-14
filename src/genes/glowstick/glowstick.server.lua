--
--	Jackson Munsell
--	28 Nov 2020
--	glowstick.server.lua
--
--	glowstick gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.glowstick)

-- Set cracked on activate
pickupUtil.getActivatedStream(genes.glowstick):map(dart.select(2)):subscribe(function (instance)
	instance.state.glowstick.cracked.Value = true
end)

-- When cracked, set to neon
genesUtil.observeStateValue(genes.glowstick, "cracked"):subscribe(function (instance, cracked)
	if cracked then
		local sound = instance:FindFirstChild("CrackSound", true)
		if sound then sound:Play() end
	end
	instance.LightPart.Material = (cracked and Enum.Material.Neon or Enum.Material.SmoothPlastic)
	fx.setFXEnabled(instance, cracked)
end)
