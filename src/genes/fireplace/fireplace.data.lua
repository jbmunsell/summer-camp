-- local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	instanceTag = "gene_fireplace",
	name = "fireplace",
	genes = {},
	state = {
		fireplace = {
			enabled = false,
			color = Color3.fromRGB(236, 139, 70),
		},
	},

	config = {
		fireplace = {
			cookRadius = 10,
			powderAffectRadius = 8,
			color = Color3.fromRGB(236, 139, 70),
			colorChangeParticleCount = 20,
		},
	},
}
