
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_door",
	name = "door",
	genes = { env.src.genes.interact },
	state = {
		open = false,
	},

	config = {
		door = {
			closedAngle = 0,
			openAngle = 90,
		},
	},
})
