
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local activity = genes.activity

local genesUtil = require(genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_activitySoccer",
	name = "soccer",
	genes = { activity },
	state = {
		soccer = {
			score = { 0, 0 },
			volleyActive = false,
			matchActive = false,
		},
	},

	config = {
		activity = {
			teamCount = 2,
		},

		soccer = {
			ball = env.res.activities.SoccerBall,
			goalsToWin = 3,
		},
	},
})
