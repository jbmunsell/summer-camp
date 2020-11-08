--
--	Jackson Munsell
--	07 Nov 2020
--	throw.server.lua
--
--	throw gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local throw = genes.throw
local pickup = genes.pickup

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local pickupUtil = require(pickup.util)
local throwUtil = require(throw.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local throws = genesUtil.initGene(throw)

-- Connect to throw activated
pickupUtil.getActivatedStream(throw)
	:subscribe(throwUtil.throwCharacterObject)

-- Set thrower to nil when it's picked up
throws
	:flatMap(function (instance)
		return rx.Observable.from(instance.state.pickup.holder)
			:filter()
			:map(dart.constant(instance))
	end)
	:subscribe(throwUtil.clearThrower)
