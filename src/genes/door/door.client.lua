--
--	Jackson Munsell
--	12 Nov 2020
--	door.client.lua
--
--	door gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules
require(env.src.genes.util).initGene(env.src.genes.door)
