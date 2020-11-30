local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_teamLink",
	name = "teamLink",
	genes = { genes.color, genes.image },
	state = {
		teamLink = {
			team = tableau.null,
		},
	},

	config = {
		teamLink = {
			team = tableau.null,
			linkFromOwnerTeam = false,
			linkColor = false,
			linkImage = false,
			teamImageType = "image",
			linkInteract = false,

			defaultImage = "",
			defaultColor = Color3.new(0.5, 0.5, 0.5),
		},
	},
}
