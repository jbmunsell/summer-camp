local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

return {
	name = "humanoidHolder",
	instanceTag = "gene_humanoidHolder",
	genes = { env.src.genes.interact },
	state = {
		humanoidHolder = {
			owner = tableau.null,
			entryOffset = CFrame.new(),
		},

		interact = {
			switches = {
				humanoidHolder = true,
			},
		},
	},

	config = {
		humanoidHolder = {
			-- animation = env.res.animations.Corpse,
		},
	},
	
	tweenInInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	tweenOutInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
}
