local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

local objectsUtil = require(env.src.objects.util)

return objectsUtil.createObjectConfig({
	className = "humanoidHolder",
	instanceTag = "Object_HumanoidHolder",
	genes = { env.src.objects.interact },
	state = {
		owner = tableau.null,
		entryOffset = CFrame.new(),
	},

	animation = env.res.animations.Corpse,
	tweenInInfo = TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	tweenOutInfo = TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
})
