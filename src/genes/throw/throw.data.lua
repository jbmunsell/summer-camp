
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)
local genes = env.src.genes

return {
	name = "throw",
	instanceTag = "gene_throw",
	genes = { genes.pickup },
	state = {
		throw = {
			thrower = tableau.null,
		},
	},
	
	config = {
		throw = {
			throwMagnitude = 50,
		},
	},
}
