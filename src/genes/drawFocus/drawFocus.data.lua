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
		},
	},

	tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
}
