-- local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes

return {
	instanceTag = "gene_team",
	name = "team",
	genes = {},
	state = {
		team = {
			wins = 0,
		},
	},

	config = {
	},
}
