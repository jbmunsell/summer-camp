
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local objectsUtil = require(env.src.objects.util)

return objectsUtil.createObjectConfig({
	instanceTag = "Object_Door",
	className = "door",
	genes = { env.src.objects.interact },
	state = {
		open = false,
	},
})
