
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

local objectsUtil = require(env.src.objects.util)

return objectsUtil.createObjectConfig({
	instanceTag = "Object_Dodgeball",
	className = "dodgeball",
	genes = { env.src.pickup },
	state = {
		hot = false,
		thrower = tableau.null,
	},
	interface = {
		events = { "TouchedNonThrowerPart" },
	},
	
	pickup = {
		stowable = false,
		touchPickupEnabled = true,
		interactPickupEnabled = false,
		buttonImage = "rbxassetid://5649977250",
	},

	throwMagnitude = 80,
})
