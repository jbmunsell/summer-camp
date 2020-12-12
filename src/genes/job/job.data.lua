-- local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_job",
	name = "job",
	genes = {},
	state = {
		job = {
		},
	},

	config = {
		job = {
			displayName = "JOB",

			displayedPerks = {},
			new = false,

			gamepassId = 0,

			gear = {},
			dailyGear = {},

			humanoidDescriptionAssets = {},
			humanoidDescription = {},

			backpackScale = 0.7,
		},
	},
}
