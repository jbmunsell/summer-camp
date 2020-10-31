--
--	Jackson Munsell
--	28 Oct 2020
--	flashlight.server.lua
--
--	Flashlight object driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local pickup = genes.pickup
local flashlight = genes.flashlight

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local pickupUtil = require(pickup.util)
local genesUtil = require(genes.util)
local flashlightUtil = require(flashlight.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init class
genesUtil.initGene(flashlight)
	:flatMap(function (instance)
		return rx.Observable.from(instance.state.flashlight.enabled)
			:map(dart.constant(instance))
	end)
	:subscribe(flashlightUtil.renderFlashlight)

-- Activated
pickupUtil.getActivatedStream(flashlight)
	:map(dart.omitFirst)
	:subscribe(flashlightUtil.toggleLightState)
