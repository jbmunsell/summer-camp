--
--	Jackson Munsell
--	13 Nov 2020
--	sessionTime.client.lua
--
--	sessionTime gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules
require(env.src.genes.util).initGene(env.src.genes.player.sessionTime)
