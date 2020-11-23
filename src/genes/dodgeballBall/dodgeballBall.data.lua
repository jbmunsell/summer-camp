
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_dodgeballBall",
	name = "dodgeballBall",
	genes = { env.src.genes.pickup },
	state = {
		dodgeballBall = {
			hot = false,
			thrower = tableau.null,
		},
	},
	interface = {
		events = { "TouchedNonThrowerPart" },
	},
	
	config = {
		pickup = {
			stowable = false,
			touchPickupEnabled = true,
			interactPickupEnabled = false,
			buttonImage = "rbxassetid://5649977250",
		},

		dodgeballBall = {
			throwMagnitude = 80,
		},
	},
}
