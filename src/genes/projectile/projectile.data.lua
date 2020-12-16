local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_projectile",
	name = "projectile",
	genes = { genes.pickup },
	state = {
		projectile = {
			charging = false,
			chargeTime = 0,
			owner = tableau.null,
			velocityMagnitude = 0,
		},
	},

	interface = {
		events = { "LocalHit", "ServerHit" },
		remoteEvents = { "RemoteHit" },
	},

	config = {
		projectile = {
			floatForceProportion = 0.8,
			chargeable = true,
			chargeTime = 3.0,
			minThrowVelocity = 50,
			maxThrowVelocity = 100,
		},
	},
}
