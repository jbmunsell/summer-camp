
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	instanceTag = "gene_foodTray",
	name = "foodTray",
	genes = { env.src.genes.pickup },

	config = {
		pickup = {
			stowable = false,
			buttonImage = "",
		},
	},
}
