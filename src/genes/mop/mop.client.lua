--
--	Jackson Munsell
--	28 Nov 2020
--	mop.client.lua
--
--	mop gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)
local mopUtil = require(genes.mop.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.mop)
