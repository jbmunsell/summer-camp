--
--	Jackson Munsell
--	11 Nov 2020
--	teamOnly.server.lua
--
--	teamOnly gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
require(genes.util).initGene(genes.multiswitch.teamOnly)
