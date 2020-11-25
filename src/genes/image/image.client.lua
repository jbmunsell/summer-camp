--
--	Jackson Munsell
--	22 Nov 2020
--	image.client.lua
--
--	image gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local imageUtil = require(genes.image.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.image):filter(dart.isDescendantOf(env.PlayerGui))
	:subscribe(imageUtil.initInstance)
