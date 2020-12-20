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
			planted = false,
		},
	},

	config = {
		projectile = {
			minThrowVelocity = 70,
			maxThrowVelocity = 150,

			hitSound = env.res.snow.audio.SnowballHit,
			launchSound = env.res.snow.audio.SnowballThrow,
		},

		snowball = {
			ragdollScaleMin = 3,
			meltTimer = 5 * 60,
		},
	},
}
