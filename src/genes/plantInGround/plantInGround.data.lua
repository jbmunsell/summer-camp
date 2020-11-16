
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	instanceTag = "gene_plantInGround",
	name = "plantInGround",
	genes = { env.src.genes.pickup },
	state = {
		plantInGround = {
			plantId = -1,
		},
	},
	
	config = {
		plantInGround = {
			initPlant = true,
		},
	},
}
