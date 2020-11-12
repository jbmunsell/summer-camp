
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_activityEnrollment",
	name = "activityEnrollment",
	genes = {  },

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
})
