local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
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
	
	tweenInInfo = TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	tweenOutInfo = TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
})
