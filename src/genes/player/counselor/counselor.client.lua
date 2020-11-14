--
--	Jackson Munsell
--	13 Nov 2020
--	counselor.client.lua
--
--	counselor gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules
require(env.src.genes.util).initGene(env.src.genes.player.counselor)
