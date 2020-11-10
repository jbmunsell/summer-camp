
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_activity",
	name = "activity",
	genes = {},
	state = {
		activity = {
			inSession = false,
			enrolledTeams = {},
			sessionTeams = {},
		},
	},

	config = {
		activity = {
			teamCount = 1,
		},
	},
})
