
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local objectsUtil = require(env.src.objects.util)

return objectsUtil.createObjectConfig({
	instanceTag = "Object_Balloon",
	className = "balloon",
	genes = { env.src.pickup },
	state = {},

	pickup = {
		buttonImage = "rbxassetid://5836949073",
	},

	maxLife = 10,
	destroyHeight = 500,
})
