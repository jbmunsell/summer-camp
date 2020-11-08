
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	name = "powderSack",
	instanceTag = "gene_powderSack",
	genes = { env.src.genes.throw },
	state = {
		powderSack = {
			poofed = false,
		},
	},
	
	config = {
		throw = {
			throwMagnitude = 50,
		},

		pickup = {
			stowable = true,
			buttonImage = "rbxassetid://5923579902",
		},

		powderSack = {
			basicPoofParticleCount = 5,
			firePoofParticleCount = 20,
			color = Color3.fromRGB(69, 103, 165),
		},
	},
})
