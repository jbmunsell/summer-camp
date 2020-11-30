local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_playerProperty",
	name = "playerProperty",
	genes = { genes.interact },
	state = {
		interact = {
			switches = {
				playerProperty = true,
			},
		},

		playerProperty = {
			owner = tableau.null,
		},
	},

	config = {
		playerProperty = {
		},
	},
}
