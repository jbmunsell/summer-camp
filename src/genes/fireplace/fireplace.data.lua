local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

local interactData = genesUtil.createGeneData({
	instanceTag = "gene_fireplace",
	name = "fireplace",
	state = {
		fireplace = {
			enabled = false,
		},
	},

	config = {
		fireplace = {
		},
	},
})

return interactData
