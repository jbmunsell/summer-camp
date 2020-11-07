
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_lightGroup",
	name = "lightGroup",
	genes = { env.src.genes.interact },
	state = {
		lightGroup = {
			switches = {
				primary = false,
			},
		},
	},
})
