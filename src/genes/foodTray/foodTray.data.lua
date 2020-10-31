
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_foodTray",
	name = "foodTray",
	genes = { env.src.genes.pickup },

	config = {
		pickup = {
			stowable = false,
			buttonImage = "",
		},
	},
})
