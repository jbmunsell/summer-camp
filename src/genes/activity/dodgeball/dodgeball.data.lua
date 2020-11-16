
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

return {
	instanceTag = "gene_activityDodgeball",
	name = "dodgeball",
	genes = { genes.activity },
	state = {
		dodgeball = {
			ragdolls = {},
		},
	},

	config = {
		activity = {
			isCompetitive = true,
			trophy = env.res.activities.DodgeballTrophy,
			displayName = "Dodgeball",
			analyticsName = "dodgeball",
			activityPromptImage = "",
			teamCount = 2,
		},

		dodgeball = {
			ball = env.res.activities.DodgeballBall,
		},
	},
}
