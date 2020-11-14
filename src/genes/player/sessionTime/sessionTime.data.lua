-- local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes

return {
	instanceTag = "gene_sessionTime",
	name = "sessionTime",
	genes = {},
	state = {
		sessionTime = {
			sessionTime = 0,
		}
	},

	config = {
	},
}
