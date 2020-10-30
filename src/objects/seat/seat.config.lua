
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local objectsUtil = require(env.src.objects.util)

return objectsUtil.createObjectConfig({
	instanceTag = "Object_Seat",
	className = "seat",
	genes = { env.src.objects.humanoidHolder },
})
