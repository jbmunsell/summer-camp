local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

local pickupConfig = {
	className = "pickup",
	instanceTag = "Pickup",
	genes = { env.src.interact },
	state = {
		enabled = true,
		dropDebounce = false,
		holder = tableau.null,
		owner = tableau.null,
	},

	dropDebounce = 1.0,
	stowable = false,
	throwOnDrop = false,
	throwOnActivated = false,
	throwMagnitude = 50,
	touchPickupEnabled = false,
	interactPickupEnabled = true,
	-- canDrop = true, -- Not currently functional because everything can be dropped
	buttonImage = "",
}

return pickupConfig
