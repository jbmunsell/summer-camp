--
--	Jackson Munsell
--	00 Mon 2020
--	_template.server.lua
--
--	_template gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)
local _templateUtil = require(genes._template.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes._template)
