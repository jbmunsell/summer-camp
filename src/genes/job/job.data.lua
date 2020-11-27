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

			gamepassId = 0,

			gear = {},
			dailyGear = {},

			humanoidDescription = {
				DepthScale = 0.7,
				WidthScale = 0.7,
				HeightScale = 0.7,
				HeadScale = 1.0,
			},

			backpackScale = 0.7,
		},
	},
}
