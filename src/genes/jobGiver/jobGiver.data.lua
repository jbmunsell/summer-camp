local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_jobGiver",
	name = "jobGiver",
	genes = { genes.interact },
	state = {
		jobGiver = {
		},
	},

	config = {
		jobGiver = {
			job = tableau.null,
		},
	},
}
