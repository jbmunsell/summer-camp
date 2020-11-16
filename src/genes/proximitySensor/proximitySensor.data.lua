-- local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes

return {
	instanceTag = "gene_proximitySensor",
	name = "proximitySensor",
	genes = {},
	state = {
		proximitySensor = {
			isInRange = false,
		},
	},

	config = {
		proximitySensor = {
			range = 15,
		},
	},
}
