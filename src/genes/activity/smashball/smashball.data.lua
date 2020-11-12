
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local activity = genes.activity

local genesUtil = require(genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_activitySmashball",
	name = "smashball",
	genes = { activity },
	state = {
		smashball = {
			roster = { {}, {} },
			ragdolls = {},
			rosterReady = false,
		},
	},

	config = {
		activity = {
			analyticsName = "smashball",
			teamCount = 2,
		},

		smashball = {
			ball = env.res.activities.SmashballBall,
			spawnRadius = 25,
		},
	},
})
