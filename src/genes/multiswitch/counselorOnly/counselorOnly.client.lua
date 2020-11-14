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
local counselorOnlyInstanceStream = genesUtil.initGene(counselorOnly)

-- Apply interact lock if we aren't a counselor
local isCounselorStream = genesUtil.observeStateValue(genes.player.counselor, "isCounselor")
	:filter(dart.equals(env.LocalPlayer))
	:map(dart.select(2))

isCounselorStream
	:flatMap(function (isCounselor)
		return rx.Observable.from(genesUtil.getInstances(counselorOnly))
			:map(dart.drag(isCounselor))
	end)
	:merge(counselorOnlyInstanceStream:withLatestFrom(isCounselorStream))
	:subscribe(function (instance, isCounselor)
		multiswitchUtil.setSwitchEnabled(instance, "interact", "counselorOnly", isCounselor)
	end)
