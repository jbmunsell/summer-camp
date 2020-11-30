--
--	Jackson Munsell
--	28 Nov 2020
--	playerProperty.client.lua
--
--	playerProperty gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

-- modules
local genesUtil = require(genes.util)
local multiswitchUtil = require(genes.multiswitch.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.playerProperty)

-- Observe state
genesUtil.observeStateValue(genes.playerProperty, "owner"):subscribe(function (instance, owner)
	multiswitchUtil.setSwitchEnabled(instance, "interact", "playerProperty", (owner == env.LocalPlayer))
end)
