local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

local interactData = genesUtil.createGeneData({
	instanceTag = "gene_interact",
	name = "interact",
	state = {
		interact = {
			switches = {
				destroyed = true,
			},
		},
	},

	config = {
		interact = {
			distanceThreshold = 40,
			duration = 0.3,
		},
	},
})

return interactData
