local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_glowstick",
	name = "glowstick",
	genes = { genes.pickup },
	state = {
		glowstick = {
			cracked = false,
		},
	},

	config = {
		glowstick = {
		},
	},
}
