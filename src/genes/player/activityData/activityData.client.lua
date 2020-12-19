--
--	Jackson Munsell
--	19 Dec 2020
--	activityData.client.lua
--
--	activityData gene client driver
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
genesUtil.initGene(genes.player.activityData)
