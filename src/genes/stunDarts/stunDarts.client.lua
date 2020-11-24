--
--	Jackson Munsell
--	24 Nov 2020
--	stunDarts.client.lua
--
--	stunDarts gene client driver
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
genesUtil.initGene(genes.stunDarts)
