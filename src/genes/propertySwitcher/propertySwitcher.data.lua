-- local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes

return {
	instanceTag = "gene_propertySwitcher",
	name = "propertySwitcher",
	genes = {},
	state = {
		propertySwitcher = {
			propertySet = "",
		},
	},

	config = {
		propertySwitcher = {
			propertySets = {},
		},
	},
}
