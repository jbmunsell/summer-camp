local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_snowball",
	name = "snowball",
	genes = { genes.projectile },
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
		projectile = {
			minThrowVelocity = 70,
			maxThrowVelocity = 150,
		},

		snowball = {
			ragdollScaleMin = 2.5,
		},
	},
}
