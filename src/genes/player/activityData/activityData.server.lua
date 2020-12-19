--
--	Jackson Munsell
--	19 Dec 2020
--	activityData.server.lua
--
--	activityData gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local playerUtil = require(genes.player.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
playerUtil.initPlayerGene(genes.player.activityData)
