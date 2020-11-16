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
		},

		interact = {
			switches = {
				pickup = true,
			},
		},
	},

	config = {
		pickup = {
			dropDebounce = 1.0,
			stowable = false,
			touchPickupEnabled = false,
			interactPickupEnabled = true,
			-- canDrop = true, -- Not currently functional because everything can be dropped
			buttonImage = "",
			buttonColor = Color3.new(1, 1, 1)
		},
	},
}
