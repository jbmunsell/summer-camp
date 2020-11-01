
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	name = "whoopieCushion",
	instanceTag = "gene_whoopieCushion",
	genes = { env.src.genes.pickup },
	state = {
		blows = 3,
		hot = false,
		filled = false,
	},
	
	config = {
		pickup = {
			throwOnActivated = true,
			throwMagnitude = 20,
			stowable = true,
			buttonImage = "",
		},

		whoopieCushion = {
			destroyFadeDuration = 0.5,
			particleCount = 10,

			fullSize = Vector3.new(1.514, 0.602, 1.987),
			emptySize = Vector3.new(1.514, 0.1, 1.987),

			tweenUpInfo = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
			tweenDownInfo = TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
		},
	},
})
