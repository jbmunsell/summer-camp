
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_flashlight",
	name = "flashlight",
	genes = { env.src.genes.pickup },
	state = {
		enabled = false,
	},
	
	config = {
		pickup = {
			stowable = true,
			buttonImage = "",
		},
	},
})
