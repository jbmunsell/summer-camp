local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_snowball",
	name = "snowball",
	genes = { genes.throw },
	state = {
		interact = {
			switches = {
				snowball = false,
			},
		},

		snowball = {
		},
	},

	config = {
		snowball = {
		},
	},
}
