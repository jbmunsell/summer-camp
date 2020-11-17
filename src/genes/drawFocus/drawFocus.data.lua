local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

return {
	instanceTag = "gene_drawFocus",
	name = "drawFocus",
	genes = { genes.proximitySensor },
	state = {
		drawFocus = {
			cameraHeadOffset = CFrame.new(),
		},
	},

	config = {
		drawFocus = {
			tweenDuration = 0.3,
		},
	},
}
