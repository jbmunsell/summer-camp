
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_teamOnly",
	name = "teamOnly",
	genes = { genes.interact },

	state = {
		interact = {
			switches = {
				teamOnly = true,
			},
		},
	},

	config = {
		teamOnly = {
			team = tableau.null,
		},
	},
})
