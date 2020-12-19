-- local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_activityData",
	name = "activityData",
	genes = {},
	state = {
		activityData = {
			kingOfTheHill = {
				hits = 1,
			},
			freezeTag = {
				frozen = false,
				freezer = false,
			},
		},
	},

	config = {
		activityData = {
		},
	},
}
