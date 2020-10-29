
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local objectsUtil = require(env.src.objects.util)

return objectsUtil.createObjectConfig({
	className = "bananaPeel",
	instanceTag = "Object_BananaPeel",
	genes = { env.src.pickup },
	state = {
		slips = 3,
		hot = true,
		expired = false,
	},
	
	pickup = {
		throwOnActivated = true,
		throwMagnitude = 50,
		stowable = true,
		buttonImage = "rbxassetid://5836949301",
	},

	peelSendMagnitude = 50,
	characterTorqueMagnitude = 150,
	characterVelocityImpulse = Vector3.new(0, 400, 0),
	peelVerticalImpulse = Vector3.new(0, 60, 0),
	peelDebounce = 0.5,
	getUpDelay = 2.0,
	destroyFadeDuration = 0.5,
})
