
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
-- local tableau = require(env.packages.axis.lib.tableau)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_plantInGround",
	name = "plantInGround",
	genes = { env.src.genes.pickup },
	state = {
		plantInGround = {
			plantId = 0,
		},
	},
	
	config = {
		plantInGround = {
			initPlant = true,
		},
	},
})
