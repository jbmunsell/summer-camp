
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)
local genes = env.src.genes

return {
	instanceTag = "gene_skewerable",
	name = "skewerable",
	genes = { genes.pickup },
	state = {
		skewerable = {
			skewer = tableau.null,
			skewerSlotIndex = -1,
		},

		interact = {
			switches = {
				skewerable = true,
			},
		},
	},

	config = {},
}
