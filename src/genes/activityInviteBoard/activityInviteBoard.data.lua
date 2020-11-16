-- local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes

return {
	instanceTag = "gene_activityInviteBoard",
	name = "activityInviteBoard",
	genes = {},
	state = {
		activityInviteBoard = {
			inviteStamps = {},
		},
	},

	config = {
		activityInviteBoard = {
			activityDisplayName = "activity-name",
			activityPromptImage = "",
			inviteCooldown = 20,
		},
	},
}
