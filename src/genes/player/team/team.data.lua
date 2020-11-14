local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

return {
	instanceTag = "gene_team",
	name = "team",
	genes = { genes.player.counselor },
	state = {
		team = {
		},
	},

	config = {
	},
}
