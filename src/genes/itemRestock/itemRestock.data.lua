local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_itemRestock",
	name = "itemRestock",
	genes = {},
	state = {
		itemRestock = {
			stock = tableau.null,
		},
	},

	config = {
		itemRestock = {
		},
	},
}
