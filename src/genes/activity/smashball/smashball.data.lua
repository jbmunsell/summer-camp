
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

return {
	instanceTag = "gene_activitySmashball",
	name = "smashball",
	genes = { genes.activity },
	state = {
		smashball = {
			roster = { {}, {} },
			ragdolls = {},
			rosterReady = false,
		},
	},

	config = {
		activity = {
			trophy = env.res.activities.SmashballTrophy,
			displayName = "Smashball",
			analyticsName = "smashball",
			teamCount = 2,
		},

		smashball = {
			ball = env.res.activities.SmashballBall,
			spawnRadius = 25,
		},
	},
}
