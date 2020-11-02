
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

local genesUtil = require(genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_skewerable",
	name = "skewerable",
	genes = { genes.pickup },
	state = {
		skewer = tableau.null,
		skewerSlotIndex = -1,
	},

	config = {},
})
