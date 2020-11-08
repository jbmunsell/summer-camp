
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	name = "throw",
	instanceTag = "gene_throw",
	genes = { env.src.genes.pickup },
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
})
