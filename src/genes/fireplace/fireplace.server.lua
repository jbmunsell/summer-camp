--
--	Jackson Munsell
--	31 Oct 2020
--	fireplace.server.lua
--
--	Fireplace gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local fireplace = genes.fireplace

-- modules
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Init gene
genesUtil.initGene(fireplace)
