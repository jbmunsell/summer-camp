
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local tableau = require(env.packages.axis.lib.tableau)
local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_playerIndicator",
	name = "playerIndicator",
	genes = {},
	state = {
		playerIndicator = {
			enabled = true,
			color = Color3.new(1, 1, 1),
			player = tableau.null,
		},
	},
	
	config = {
	},
})
