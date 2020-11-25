--
--	Jackson Munsell
--	24 Nov 2020
--	patch.server.lua
--
--	patch gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local genesUtil = require(genes.util)
local patchUtil = require(genes.patch.util)
local multiswitchUtil = require(genes.multiswitch.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.patch)

-- Set the patch switch according to our attached value
genesUtil.observeStateValue(genes.patch, "attached"):subscribe(function (instance, attached)
	multiswitchUtil.setSwitchEnabled(instance, "interact", "patch", not attached)
end)

-- Attach patch on request
rx.Observable.from(genes.patch.net.AttachRequested)
	:filter(function (player, instance)
		print(player, instance)
		return instance.state.pickup.owner.Value == player
	end)
	:subscribe(patchUtil.attachPatch)
