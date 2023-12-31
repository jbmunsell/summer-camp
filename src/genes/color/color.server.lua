--
--	Jackson Munsell
--	12 Nov 2020
--	color.server.lua
--
--	color gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)
local colorUtil = require(genes.color.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.color):subscribe(colorUtil.initInstance)
