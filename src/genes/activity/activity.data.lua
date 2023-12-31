
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
			fullRoster = { {}, {}, {}, {} },
			score = { 0, 0, 0, 0 },
			isCollectingRoster = false,
			winningTeam = tableau.null,
			gear = {},
			ragdolls = {},
		},
	},

	config = {
		activity = {
			isCompetitive = false,
			lockPitch = false,
			sharesPitch = false,
			pitch = tableau.null,
			rosterCollectionTimer = 25,
			trophy = tableau.null,
			teamCount = 1,
			minPlayersPerTeam = 1,
			maxPlayersPerTeam = 100,
			
			displayName = "Activity",
			analyticsName = "activity",
			activityPromptImage = "",

			gear = {},
		},
	},

}
