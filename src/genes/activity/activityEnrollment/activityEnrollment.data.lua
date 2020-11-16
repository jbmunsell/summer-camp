
-- env
-- local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	instanceTag = "gene_activityEnrollment",
	name = "activityEnrollment",
	genes = {},

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
		events = {},
	},
	
	config = {
		activityEnrollment = {
			triggerDistance = 10,
		},
	},
}
