--
--	Jackson Munsell
--	15 Nov 2020
--	proximitySensor.server.lua
--
--	proximitySensor gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local proximitySensor = genes.proximitySensor

-- modules
local genesUtil = require(genes.util)

-- Bind all instances
genesUtil.initGene(proximitySensor)
