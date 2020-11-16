local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

return {
	instanceTag = "gene_leader",
	name = "leader",
	genes = { genes.player.sessionTime },
	state = {
		leader = {
			isLeader = false,
		}
	},

	config = {
	},
}
