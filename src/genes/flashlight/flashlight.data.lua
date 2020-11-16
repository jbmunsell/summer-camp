
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	instanceTag = "gene_flashlight",
	name = "flashlight",
	genes = { env.src.genes.pickup },
	state = {
		flashlight = {
			enabled = false,
		},
	},
	
	config = {
		pickup = {
			stowable = true,
			buttonImage = "rbxassetid://5912717016",
		},
	},
}
