
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local activity = genes.activity

local genesUtil = require(genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_activityDodgeball",
	name = "dodgeball",
	genes = { activity },
	state = {
		dodgeball = {
			matchActive = false,
			roster = { {}, {} },
			ragdolls = {},
			rosterReady = false,
		},
	},

	config = {
		activity = {
			teamCount = 2,
		},

		dodgeball = {
			ball = env.res.activities.DodgeballBall,
		},
	},
})
