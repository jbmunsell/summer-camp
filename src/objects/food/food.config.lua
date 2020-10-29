
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

local objectsUtil = require(env.src.objects.util)

return objectsUtil.createObjectConfig({
	instanceTag = "Object_Food",
	className = "food",
	genes = { env.src.objects.pickup },
	state = {
		tray = tableau.null,
	},

	pickup = {
		stowable = false,
		buttonImage = "",
	},
})
