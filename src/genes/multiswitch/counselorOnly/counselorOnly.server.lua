--
--	Jackson Munsell
--	10 Nov 2020
--	counselorOnly.server.lua
--
--	counselorOnly gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
require(genes.util).initGene(genes.multiswitch.counselorOnly)
