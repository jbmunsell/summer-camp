
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local tableau = require(env.packages.axis.lib.tableau)
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
			winningTeam = tableau.null,
		},
	},

	config = {
		activity = {
			trophy = env.res.activities.PlaceholderTrophy,
			teamCount = 1,
		},
	},
})
