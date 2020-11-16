
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	instanceTag = "gene_pulloutChair",
	name = "pulloutChair",
	genes = { env.src.genes.seat },

	config = {
		pulloutChair = {
			pulloutTranslation = CFrame.new(-2, 0, 0),
		},
	},

	tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
}
