
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

return {
	name = "whoopieCushion",
	instanceTag = "gene_whoopieCushion",
	genes = { genes.throw },
	state = {
		whoopieCushion = {
			blows = 10,
			hot = false,
			filled = false,
		},
	},
	
	config = {
		throw = {
			throwMagnitude = 20,
		},

		pickup = {
			stowable = true,
			buttonImage = "rbxassetid://5912747171",
		},

		whoopieCushion = {
			destroyFadeDuration = 0.5,
			particleCount = 10,

			fullSize = Vector3.new(1.514, 0.602, 1.987),
			emptySize = Vector3.new(1.514, 0.1, 1.987),
		},
	},

	tweenUpInfo = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	tweenDownInfo = TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
}
