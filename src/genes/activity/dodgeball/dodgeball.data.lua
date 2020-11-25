
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
			lockPitch = true,
			trophy = env.res.activities.DodgeballTrophy,
			patch = env.res.activities.DodgeballWinPatch,
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
