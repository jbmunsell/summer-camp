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
		captureTheFlag = {
			isCompetitive = true,
			-- lockPitch = true,
			-- trophy = env.res.activities.CaptureTheFlagTrophy,
			displayName = "Capture the Flag",
			analyticsName = "captureTheFlag",
			-- activityPromptImage = "",
			teamCount = 2,

			gear = {
				env.res.activities.StunDarts,
			},
		},
	},
}
