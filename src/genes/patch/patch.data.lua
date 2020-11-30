local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_patch",
	name = "patch",
	genes = { genes.pickup },
	state = {
		patch = {
			attached = false,
			owner = tableau.null,
			attachmentCFrame = CFrame.new(0, 0, 0),
		},

		interact = {
			switches = {
				patch = true,
			},
		},
	},

	config = {
		pickup = {
			stowable = true,
		},

		patch = {
		},
	},
}
