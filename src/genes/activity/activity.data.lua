
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_activity",
	name = "activity",
	genes = {},
	state = {
		activity = {
			inSession = false,
			enrolledTeams = {},
			sessionTeams = {},
			roster = { {}, {}, {}, {} },
			score = { 0, 0, 0, 0 },
			isCollectingRoster = false,
			winningTeam = tableau.null,
		},
	},

	config = {
		activity = {
			isCompetitive = false,
			rosterCollectionTimer = 25,
			trophy = env.res.activities.PlaceholderTrophy,
			teamCount = 1,
			
			displayName = "Activity",
			analyticsName = "activity",
			activityPromptImage = "",
		},
	},

}
