--
--	Jackson Munsell
--	22 Nov 2020
--	image.server.lua
--
--	image gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)
local imageUtil = require(genes.image.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.image):subscribe(imageUtil.initInstance)
