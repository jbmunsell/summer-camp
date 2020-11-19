--
--	Jackson Munsell
--	19 Nov 2020
--	megaphone.client.lua
--
--	megaphone gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
genesUtil.initGene(genes.megaphone)
