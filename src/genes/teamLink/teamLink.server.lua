--
--	Jackson Munsell
--	22 Nov 2020
--	teamLink.server.lua
--
--	teamLink gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)
local teamLinkUtil = require(genes.teamLink.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.teamLink):subscribe(teamLinkUtil.initTeamLink)
