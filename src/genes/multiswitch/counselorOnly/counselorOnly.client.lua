--
--	Jackson Munsell
--	10 Nov 2020
--	counselorOnly.client.lua
--
--	counselorOnly gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local multiswitch = genes.multiswitch
local counselorOnly = multiswitch.counselorOnly

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local multiswitchUtil = require(multiswitch.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(counselorOnly)

-- Apply interact lock if we aren't a counselor
genesUtil.observeStateValue(genes.player.counselor, "isCounselor")
	:filter(dart.equals(env.LocalPlayer))
	:flatMap(function (_, isCounselor)
		return rx.Observable.from(genesUtil.getInstances(counselorOnly))
			:map(dart.drag("interact", "counselorOnly", isCounselor))
	end)
	:subscribe(multiswitchUtil.setSwitchEnabled)
