--
--	Jackson Munsell
--	16 Nov 2020
--	team.client.lua
--
--	team gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)

-- init gene
genesUtil.initGene(genes.team)
