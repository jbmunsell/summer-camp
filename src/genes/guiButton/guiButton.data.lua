-- local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_guiButton",
	name = "guiButton",
	genes = {},
	state = {
		guiButton = {
			gamepadControlEnabled = false,
		},
	},

	interface = {
		events = { "Activated" },
	},

	config = {
		guiButton = {
			gamepadButton = "",
			gamepadButtonImageType = "dark",
		},
	},
}
