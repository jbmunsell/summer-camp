local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

return {
	instanceTag = "gene_megaphone",
	name = "megaphone",
	genes = { genes.pickup, genes.color },
	state = {
	},

	config = {
		pickup = {
			stowable = true,
		},
	},
}
