local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_preventRunning",
	name = "preventRunning",
	genes = { genes.pickup },
	state = {
		preventRunning = {
		},
	},

	config = {
		preventRunning = {
		},
	},
}
