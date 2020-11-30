--
--	Jackson Munsell
--	24 Nov 2020
--	stunDarts.server.lua
--
--	stunDarts gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)
local stunDartsUtil = require(genes.stunDarts.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.stunDarts)

-- Fire on activated
pickupUtil.getActivatedStream(genes.stunDarts):subscribe(function (character, instance, target)
	if not stunDartsUtil.processDebounce(instance) then return end
	stunDartsUtil.fireDart(character, instance, axisUtil.getPosition(instance), target)
end)
