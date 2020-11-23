local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_job",
	name = "job",
	genes = {},
	state = {
		job = {
			job = env.res.jobs.teamLeader,
			wearClothes = true,
			gear = {},
		},
	},

	config = {
		job = {
		},
	},
}
