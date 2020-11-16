
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	instanceTag = "gene_skewer",
	name = "skewer",
	genes = { env.src.genes.pickup },

	config = {
		skewer = {
			maxSkewerSlots = 3,
		},

		pickup = {
			stowable = false,
			buttonImage = "rbxassetid://5923387058",
		},
	},
}
