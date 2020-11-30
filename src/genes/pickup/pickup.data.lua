local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

return {
	name = "pickup",
	instanceTag = "gene_pickup",
	genes = { env.src.genes.interact },
	state = {
		pickup = {
			enabled = true,
			dropDebounce = false,
			holder = tableau.null,
			owner = tableau.null,
			activity = tableau.null,
		},

		interact = {
			switches = {
				pickup = true,
			},
		},
	},

	config = {
		pickup = {
			extras = {},
			holdAnimation = env.res.pickup.DefaultHoldAnimation,
			activationAnimation = tableau.null,
			dropDebounce = 1.0,
			stowable = false,
			touchPickupEnabled = false,
			interactPickupEnabled = true,
			canDrop = true,
			buttonImage = "",
			buttonColor = Color3.new(1, 1, 1)
		},
	},
}
