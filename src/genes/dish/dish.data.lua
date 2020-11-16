
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_dish",
	name = "dish",
	genes = { genes.edible },
	state = {
		dish = {
			tray = tableau.null,
			eaten = false,
		},

		interact = {
			switches = {
				dish = true,
			},
		},
	},

	config = {
		pickup = {
			stowable = false,
			buttonImage = "",
		},
	},
}
