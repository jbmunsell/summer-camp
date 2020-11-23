
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

return {
	instanceTag = "gene_activitySoccer",
	name = "soccer",
	genes = { genes.activity },
	state = {
		soccer = {
			score = { 0, 0 },
			volleyActive = false,
			matchActive = false,
		},
	},

	config = {
		activity = {
			isCompetitive = true,
			lockPitch = true,
			trophy = env.res.activities.SoccerTrophy,
			displayName = "Soccer",
			analyticsName = "soccer",
			activityPromptImage = "rbxassetid://179546941",
			teamCount = 2,
		},

		soccer = {
			ball = env.res.activities.SoccerBall,
			goalsToWin = 3,
		},
	},
}
