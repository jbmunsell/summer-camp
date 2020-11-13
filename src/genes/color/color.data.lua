local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

local interactData = genesUtil.createGeneData({
	instanceTag = "gene_color",
	name = "color",
	genes = {},
	state = {
		color = {
			color = Color3.new(0.5, 0.5, 0.5),
		},
	},

	config = {
		color = {
			color = Color3.new(0.5, 0.5, 0.5),
		},
	},
})

return interactData
