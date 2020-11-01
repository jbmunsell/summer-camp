
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_stick",
	name = "stick",
	genes = { env.src.genes.pickup },

	config = {
		pickup = {
			stowable = false,
			buttonImage = "",
		},
	},
})
