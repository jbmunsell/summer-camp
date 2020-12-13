--
--	Jackson Munsell
--	12 Dec 2020
--	chalkBlackboard.client.lua
--
--	chalkBlackboard gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.chalkBlackboard)
