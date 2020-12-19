local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_activityKingOfTheHill",
	name = "kingOfTheHill",
	genes = { genes.activity },
	state = {
		kingOfTheHill = {
			capturingTeam = tableau.null,
		},
	},

	config = {
		activity = {
			isCompetitive = true,
			lockPitch = true,
			trophy = env.res.activities.SnowballTrophy,
			-- patch = env.res.activities.SoccerWinPatch,
			displayName = "Snowball Fight",
			analyticsName = "kingOfTheHill",
			activityPromptImage = "",
			teamCount = 2,
		},

		kingOfTheHill = {
			playerHits = 3,
			timeToWin = 60,
		},
	},
}
