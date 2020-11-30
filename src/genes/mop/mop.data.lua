local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_mop",
	name = "mop",
	genes = { genes.pickup },
	state = {
		mop = {
			debounce = false,
		},
	},

	config = {
		mop = {
			debounceTimer = 3.0,
			puddleDuration = 7.0,
		},
	},
}
