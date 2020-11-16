
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

return {
	instanceTag = "gene_edible",
	name = "edible",
	genes = { genes.pickup },
	state = {
		edible = {
			eaten = false,
		},
	},

	config = {},
}
