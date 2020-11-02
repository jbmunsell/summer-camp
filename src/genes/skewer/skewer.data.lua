
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_skewer",
	name = "skewer",
	genes = { env.src.genes.pickup },

	config = {
		skewer = {
			maxSkewerSlots = 3,
		},

		pickup = {
			stowable = false,
			buttonImage = "",
		},
	},
})
