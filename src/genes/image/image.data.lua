-- local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_image",
	name = "image",
	genes = {},
	state = {
		image = {
			image = "",
		},
	},

	config = {
		image = {
			image = "",
		},
	},
}
