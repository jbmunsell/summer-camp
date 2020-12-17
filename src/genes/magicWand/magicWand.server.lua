--
--	Jackson Munsell
--	29 Nov 2020
--	magicWand.server.lua
--
--	magicWand gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.magicWand)

-- Teleport on activated
pickupUtil.getActivatedStream(genes.magicWand):subscribe(function (character, _, target)
	local cframe = character:GetPrimaryPartCFrame()
	cframe = cframe - cframe.p + target + Vector3.new(0, 3, 0)
	pickupUtil.teleportCharacterWithHeldObjects(character, cframe)
end)
