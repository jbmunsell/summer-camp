
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	instanceTag = "gene_plantInGround",
	name = "plantInGround",
	genes = { env.src.genes.throw },
	state = {
		plantInGround = {
			plantId = -1,
			planted = false,
		},
	},
	
	config = {
		throw = {
			throwMagnitude = 0,
		},

		plantInGround = {
			initPlant = true,
		},
	},
}
