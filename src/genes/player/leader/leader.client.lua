--
--	Jackson Munsell
--	13 Nov 2020
--	leader.client.lua
--
--	leader gene client driver
--

-- env
-- local StarterGui = game:GetService("StarterGui")
local env = require(game:GetService("ReplicatedStorage").src.env)
-- local axis = env.packages.axis
local genes = env.src.genes

-- modules
-- local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
genesUtil.initGene(env.src.genes.player.leader)
