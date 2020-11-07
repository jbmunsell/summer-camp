
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_canvas",
	name = "canvas",
	genes = { env.src.genes.interact },
	state = {
		canvas = {
			owner = tableau.null,
			teamToAcceptFrom = tableau.null,
			locked = false,
		},
	},

	config = {
		canvas = {
			activeToolHighlightColor = Color3.fromRGB(190, 145, 255),
		},
	},
})
