local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_stunDarts",
	name = "stunDarts",
	genes = { genes.pickup },
	state = {
		stunDarts = {
		},
	},

	config = {
		stunDarts = {
			shootMagnitude = 120,
			projectile = env.res.objects.DartProjectile,
		},
	},
}
