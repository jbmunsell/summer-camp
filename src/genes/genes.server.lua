--
--	Jackson Munsell
--	15 Nov 2020
--	genes.server.lua
--
--	genes server driver - inits queue processing
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules
local genesUtil = require(env.src.genes.util)

-- Init processing
genesUtil.initQueueProcessing(10)
