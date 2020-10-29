
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local objectsUtil = require(env.src.objects.util)

return objectsUtil.createObjectConfig({
	instanceTag = "Object_FoodTray",
	className = "foodTray",
	genes = { env.src.pickup },

	pickup = {
		stowable = false,
		buttonImage = "",
	},
})
