--
--	Jackson Munsell
--	06 Nov 2020
--	nighttimeSwitch.server.lua
--
--	nighttimeSwitch gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
require(genes.util).initGene(genes.multiswitch.timeOfDaySwitch.nighttimeSwitch)
