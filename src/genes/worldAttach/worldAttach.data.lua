local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_worldAttach",
	name = "worldAttach",
	genes = { genes.pickup },
	state = {
		worldAttach = {
			count = 1,
		},
	},

	interface = {
		events = {"PreviewCreated"},
	},

	config = {
		worldAttach = {
			attachableTags = {},
			attachableTerrainMaterials = {},
			count = 3,

			attachRange = 20,
			rotationRange = 6,

			characterAttachTimer = 20,
			attachTimer = 5 * 60,
			removeAfterOwnerLeft = true,

			attachSound = tableau.null,
		},
	},
}
