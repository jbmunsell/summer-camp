local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_securityCameraViewer",
	name = "securityCameraViewer",
	genes = { genes.pickup },
	state = {
		securityCameraViewer = {
		},
	},

	config = {
		securityCameraViewer = {
		},
	},
}
