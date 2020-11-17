
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

return {
	instanceTag = "gene_marshmallow",
	name = "marshmallow",
	genes = { genes.edible, genes.skewerable },
	state = {
		marshmallow = {
			isCooking = false,
			fireTime = 0,
			stage = "normal",
			destroyed = false,
		},
	},

	config = {
		marshmallow = {
			fireTimeMax = 30,
			stages = {
				normal = {
					time = 0.0,
					size = Vector3.new(0.415, 0.447, 0.419),
					texture = "",
				},
				cooked = {
					time = 0.33,
					size = Vector3.new(0.415, 0.447, 0.419),
					texture = "rbxgameasset://Images/CookedTexture",
				},
				burnt = {
					time = 0.67,
					size = Vector3.new(0.421, 0.456, 0.421),
					texture = "rbxgameasset://Images/BurntTexture",
				},
			},
		},

		pickup = {
			stowable = false,
			buttonImage = "rbxassetid://5923567209",
		},
	},
}
