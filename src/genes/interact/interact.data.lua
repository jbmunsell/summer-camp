-- local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	instanceTag = "gene_interact",
	name = "interact",
	genes = {},
	state = {
		interact = {
			stamp = 0,
			switches = {
				destroyed = true,
			},
		},
	},

	config = {
		interact = {
			distanceThreshold = 20,
			duration = 0.3,
		},
	},
}
