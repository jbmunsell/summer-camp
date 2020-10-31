
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_dodgeball",
	name = "dodgeball",
	genes = { env.src.genes.pickup },
	state = {
		hot = false,
		thrower = tableau.null,
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

		dodgeball = {
			throwMagnitude = 80,
		},
	},
})