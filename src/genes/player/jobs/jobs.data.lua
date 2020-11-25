local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_playerJobs",
	name = "jobs",
	genes = {},
	state = {
		jobs = {
			job = env.res.jobs.teamLeader,
			wearClothes = true,
			gear = {},
			unlocked = {},
			dailyGearGiven = {},
		},
	},

	config = {
		jobs = {
		},
	},
}
