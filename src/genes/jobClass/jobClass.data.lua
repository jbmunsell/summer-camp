-- local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_jobClass",
	name = "jobClass",
	genes = {},
	state = {
		jobClass = {
		},
	},

	config = {
		jobClass = {
			clothes = {},

			gear = {},

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
