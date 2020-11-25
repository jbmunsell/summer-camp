--
--	Jackson Munsell
--	15 Nov 2020
--	genes.client.lua
--
--	genes client driver - inits queue processing (player gui only)
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules
local genesUtil = require(env.src.genes.util)

-- Init processing
genesUtil.initQueueProcessing(10)
