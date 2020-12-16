local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_snowShovel",
	name = "snowShovel",
	genes = { genes.pickup },
	state = {
		snowShovel = {
			buildTimer = 0,
		},
	},

	config = {
		pickup = {
			canDrop = false,
			stowable = true,
		},

		snowShovel = {
			buildTimer = 1,
			buildRange = 20,
		},
	},
}
