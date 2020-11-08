local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

local interactData = genesUtil.createGeneData({
	instanceTag = "gene_fireplace",
	name = "fireplace",
	state = {
		fireplace = {
			enabled = false,
			color = Color3.new(236, 139, 70),
		},
	},

	config = {
		fireplace = {
			cookRadius = 14,
			powderAffectRadius = 5,
			color = Color3.new(236, 139, 70),
			colorChangeParticleCount = 20,
		},
	},
})

return interactData
