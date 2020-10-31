--
--	Jackson Munsell
--	04 Sep 2020
--	interact.server.lua
--
--	Server interact functionality
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local interact = genes.interact

-- modules
local genesUtil = require(genes.util)

-- Init all interactables
genesUtil.initGene(interact)
