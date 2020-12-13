local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_chalkBlackboard",
	name = "chalkBlackboard",
	genes = { genes.textConfigure },
	state = {
		chalkBlackboard = {
		},
	},

	config = {
		textConfigure = {
			text = "Use chalk to edit this text.",
		},

		chalkBlackboard = {
			reach = 20,
		},
	},
}
