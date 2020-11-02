--
--	Jackson Munsell
--	01 Nov 2020
--	skewer.util.lua
--
--	skewer gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local skewerable = genes.skewerable

-- modules
local genesUtil = require(genes.util)

-- lib
local skewerUtil = {}

-- Get skewered
function skewerUtil.getSkewered(instance)
	return genesUtil.getInstances(skewerable)
		:filter(function (v)
			return v.state.skewerable.skewer.Value == instance
		end)
end

-- return lib
return skewerUtil
