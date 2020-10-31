
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_balloon",
	name = "balloon",
	genes = { env.src.genes.pickup },
	state = {},

	config = {
		pickup = {
			buttonImage = "rbxassetid://5836949073",
		},

		balloon = {
			maxLife = 10,
			destroyHeight = 500,
		},
	},
})