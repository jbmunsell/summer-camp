--
--	Jackson Munsell
--	12 Nov 2020
--	dodgeball.client.lua
--
--	dodgeball gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules
require(env.src.genes.util).initGene(env.src.genes.activity.dodgeball)
