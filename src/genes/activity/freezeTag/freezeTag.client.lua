--
--	Jackson Munsell
--	19 Dec 2020
--	freezeTag.client.lua
--
--	freezeTag gene client driver
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
genesUtil.initGene(genes.activity.freezeTag)
