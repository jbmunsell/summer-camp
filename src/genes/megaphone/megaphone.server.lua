--
--	Jackson Munsell
--	19 Nov 2020
--	megaphone.server.lua
--
--	megaphone gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
genesUtil.initGene(genes.megaphone)

-- Render color
genesUtil.crossObserveStateValue(genes.megaphone, genes.color, "color"):subscribe(function (instance, color)
	instance.MegaphoneColor.Color = color
end)
