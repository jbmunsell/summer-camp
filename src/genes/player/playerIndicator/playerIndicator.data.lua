
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_playerIndicator",
	name = "playerIndicator",
	genes = {},
	state = {
		playerIndicator = {
			enabled = false,
			color = Color3.new(1, 1, 1),
			player = tableau.null,
		},
	},
	
	config = {
	},
}
