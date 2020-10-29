
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local objectsUtil = require(env.src.objects.util)

return objectsUtil.createObjectConfig({
	instanceTag = "Object_Mattress",
	className = "mattress",
	genes = { env.src.objects.humanoidHolder },

	-- humanoidHolder = {
	-- 	animation = env.res.animations.Corpse,
	-- },
})
