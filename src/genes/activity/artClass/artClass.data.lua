
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local activity = genes.activity

local genesUtil = require(genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_activityArtClass",
	name = "artClass",
	genes = { activity },
	state = {
	},

	config = {
	},
})
