local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_chalk",
	name = "chalk",
	genes = { genes.pickup, genes.textConfigure },
	state = {
		chalk = {
		},
	},

	config = {
		chalk = {
			reach = 20,
		},
	},
}
