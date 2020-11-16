
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	name = "powderSack",
	instanceTag = "gene_powderSack",
	genes = { env.src.genes.throw, env.src.genes.color },
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
		},
	},
}
