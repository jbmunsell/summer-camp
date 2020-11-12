--
--	Jackson Munsell
--	12 Nov 2020
--	color.server.lua
--
--	color gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local colored = require(genes.util).initGene(genes.color)

-- Pull from config on init
colored:subscribe(function (instance)
	instance.state.color.color.Value = instance.config.color.color.Value
end)
