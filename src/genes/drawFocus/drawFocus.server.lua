--
--	Jackson Munsell
--	15 Nov 2020
--	drawFocus.server.lua
--
--	drawFocus gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local drawFocus = genes.drawFocus

-- modules
local genesUtil = require(genes.util)

-- Bind all instances
genesUtil.initGene(drawFocus)
