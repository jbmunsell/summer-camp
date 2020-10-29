
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local objectsUtil = require(env.src.objects.util)

return objectsUtil.createObjectConfig({
	instanceTag = "Object_Flashlight",
	className = "flashlight",
	genes = { env.src.objects.pickup },
	state = {
		enabled = false,
	},
	
	pickup = {
		stowable = true,
		buttonImage = "",
	},
})
