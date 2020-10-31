
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_food",
	name = "food",
	genes = { env.src.genes.pickup },
	state = {
		tray = tableau.null,
		eaten = false,
	},

	config = {
		pickup = {
			stowable = false,
			buttonImage = "",
		},
	},
})
