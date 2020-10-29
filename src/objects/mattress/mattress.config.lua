
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

local objectsUtil = require(env.src.objects.util)

return objectsUtil.createObjectConfig({
	instanceTag = "Object_Mattress",
	className = "mattress",
	genes = { env.src.objects.interact },
	state = {
		owner = tableau.null,
	},

	layTweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
})
