local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_stunDarts",
	name = "stunDarts",
	genes = { genes.pickup },
	state = {
		stunDarts = {
			activity = tableau.null,
			debounce = false,
		},
	},

	config = {
		pickup = {
			canDrop = false,
			stowable = true,
		},

		stunDarts = {
			debounce = 2,
			shootMagnitude = 120,
			projectile = env.res.activities.gear.DartProjectile,
			characterParticles = env.res.activities.gear.StunEffect,
		},
	},
}
