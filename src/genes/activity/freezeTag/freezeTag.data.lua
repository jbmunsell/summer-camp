local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_activityFreezeTag",
	name = "freezeTag",
	genes = { genes.activity },
	state = {
		freezeTag = {
		},
	},

	config = {
		activity = {
			isCompetitive = true,
			lockPitch = true,
			trophy = env.res.activities.FreezeTagTrophy,
			patch = env.res.activities.FreezeTagPatch,
			displayName = "Freeze Tag",
			analyticsName = "freezeTag",
			activityPromptImage = "",
			teamCount = 2,
			minPlayersPerTeam = 2,
		},

		freezeTag = {
		},
	},
}
