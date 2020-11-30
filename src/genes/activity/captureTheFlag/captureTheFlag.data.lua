local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_activityCaptureTheFlag",
	name = "captureTheFlag",
	genes = { genes.activity },
	state = {
		captureTheFlag = {
		},
	},

	config = {
		activity = {
			isCompetitive = true,
			-- lockPitch = true,
			trophy = env.res.activities.CaptureTheFlagTrophy,
			patch = env.res.activities.CaptureTheFlagWinPatch,
			displayName = "Capture the Flag",
			analyticsName = "captureTheFlag",
			-- activityPromptImage = "",
			teamCount = 2,

			gear = {
				env.res.activities.gear.StunGun,
			},
		},
	},
}
