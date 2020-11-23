local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_teamLink",
	name = "teamLink",
	genes = {},
	state = {
		teamLink = {
			team = tableau.null,
		},
	},

	config = {
		teamLink = {
			team = tableau.null,
			linkColor = false,
			linkImage = false,
			linkInteract = false,
		},
	},
}
