local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_playerJobs",
	name = "jobs",
	genes = {},
	state = {
		jobs = {
			job = env.res.jobs.camper,
			-- job = tableau.null,
			outfitsEnabled = true,
			avatarScale = env.config.character.scaleDefault.Value,
			gear = {},
			unlocked = {},
			playerClothes = {},
			dailyGearGiven = {},
		},
	},

	config = {
		jobs = {
		},
	},
}
