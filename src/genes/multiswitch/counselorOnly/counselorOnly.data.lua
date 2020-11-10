
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_counselorOnly",
	name = "counselorOnly",
	genes = { genes.interact },

	state = {
		interact = {
			switches = {
				counselorOnly = true,
			},
		},
	},
})
