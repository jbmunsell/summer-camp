local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_snowMittens",
	name = "snowMittens",
	genes = { genes.pickup },
	state = {
		snowMittens = {
			gathering = false,
		},
	},

	config = {
		pickup = {
			stowable = true,
			canDrop = false,
		},

		snowMittens = {
		},
	},
}
