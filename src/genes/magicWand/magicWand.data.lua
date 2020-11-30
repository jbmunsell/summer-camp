local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes
-- local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_magicWand",
	name = "magicWand",
	genes = { genes.pickup },
	state = {
		magicWand = {
		},
	},

	config = {
		pickup = {
			stowable = true,
			canDrop = true,
			buttonImage = "http://www.roblox.com/asset/?id=278148849",
		},

		magicWand = {
		},
	},
}
