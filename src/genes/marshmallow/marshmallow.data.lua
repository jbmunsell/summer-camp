
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

local genesUtil = require(genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_marshmallow",
	name = "marshmallow",
	genes = { genes.edible },
	state = {
		fireTime = 0,
		stage = "normal",
		destroyed = false,
		
		stick = tableau.null,
		stickSlotIndex = 0,
	},

	config = {
		marshmallow = {
			fireTimeMax = 30,
			cookDistanceThreshold = 20,
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
			buttonImage = "",
		},
	},
})
