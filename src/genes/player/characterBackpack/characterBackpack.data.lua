local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)
-- local genes = env.src.genes

return {
	instanceTag = "gene_characterBackpack",
	name = "characterBackpack",
	genes = {},
	state = {
		characterBackpack = {
			destroyed = false,
			instance = tableau.null,
		}
	},

	config = {
	},
}
