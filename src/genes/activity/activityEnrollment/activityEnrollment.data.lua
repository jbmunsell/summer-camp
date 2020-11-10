
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_activityEnrollment",
	name = "activityEnrollment",
	genes = { genes.interact, genes.multiswitch.counselorOnly },

	state = {
		interact = {
			switches = {
				activityEnrollment = true,
			},
		},

		activityEnrollment = {
			visible = false,
		},
	},

	interface = {
		events = { "cabinCounselorTriggered" },
	},
	
	config = {
		activityEnrollment = {
			triggerDistance = 10,
		},
	},

	transparencyTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear),
})
