
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

local genesUtil = require(genes.util)

return genesUtil.createGeneData({
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
})
