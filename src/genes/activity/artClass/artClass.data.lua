
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

return {
	instanceTag = "gene_activityArtClass",
	name = "artClass",
	genes = { genes.activity },
	state = {
	},

	config = {
		activity = {
			isCompetitive = false,
			displayName = "Art Class",
			analyticsName = "artClass",
		},
	},
}
