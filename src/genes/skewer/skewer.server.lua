--
--	Jackson Munsell
--	31 Oct 2020
--	skewer.server.lua
--
--	skewer gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local skewer = genes.skewer
local pickup = genes.pickup
local edible = genes.edible

-- modules
local genesUtil = require(genes.util)
local skewerUtil = require(skewer.util)
local pickupUtil = require(pickup.util)
local edibleUtil = require(edible.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Bind all skewers
genesUtil.initGene(skewer)

-- Eat top item on activated
pickupUtil.getActivatedStream(skewer)
	:map(function (_, instance)
		return skewerUtil.getSkewered(instance)
			:first()
	end)
	:filter()
	:subscribe(edibleUtil.eat)
