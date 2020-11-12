
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_balloon",
	name = "balloon",
	genes = { env.src.genes.pickup, env.src.genes.color },
	state = {
		balloon = {

		},

		interact = {
			switches = {
				balloon = true,
			},
		},
	},

	config = {
		pickup = {
			buttonImage = "rbxassetid://5836949073",
		},

		balloon = {
			lifetime = 30,
			destroyHeight = 500,
		},
	},
})
