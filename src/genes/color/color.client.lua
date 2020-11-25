--
--	Jackson Munsell
--	12 Nov 2020
--	color.client.lua
--
--	color gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local colorUtil = require(genes.color.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.color):filter(dart.isDescendantOf(env.PlayerGui))
	:subscribe(colorUtil.initInstance)
