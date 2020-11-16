
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)
local genes = env.src.genes

return {
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
}
