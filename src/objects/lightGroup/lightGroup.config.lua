
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local objectsUtil = require(env.src.objects.util)

return objectsUtil.createObjectConfig({
	instanceTag = "Object_LightGroup",
	className = "lightGroup",
	genes = { env.src.objects.interact },
	state = {
		enabled = false,
	},
})
