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
local objects = env.src.objects
local pickup = objects.pickup
local flashlight = objects.flashlight

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local pickupUtil = require(pickup.util)
local objectsUtil = require(objects.util)
local flashlightUtil = require(flashlight.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init class
objectsUtil.initObjectClass(flashlight)
	:flatMap(function (instance)
		return rx.Observable.from(instance.state.flashlight.enabled)
			:map(dart.constant(instance))
	end)
	:subscribe(flashlightUtil.renderFlashlight)

-- Activated
pickupUtil.getActivatedStream(flashlight)
	:map(dart.omitFirst)
	:subscribe(flashlightUtil.toggleLightState)
