local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

return {
	instanceTag = "gene_counselor",
	name = "counselor",
	genes = { genes.player.sessionTime },
	state = {
		counselor = {
			isCounselor = false,
		}
	},

	config = {
	},

	campersPerCounselor = 6,
}
