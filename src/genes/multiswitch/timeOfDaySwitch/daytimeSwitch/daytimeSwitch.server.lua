--
--	Jackson Munsell
--	06 Nov 2020
--	daytimeSwitch.server.lua
--
--	daytimeSwitch gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
require(genes.util).initGene(genes.multiswitch.timeOfDaySwitch.daytimeSwitch)
