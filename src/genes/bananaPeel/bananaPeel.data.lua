
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	name = "bananaPeel",
	instanceTag = "gene_bananaPeel",
	genes = { env.src.genes.throw },
	state = {
		bananaPeel = {
			slips = 8,
			hot = true,
			expired = false,
		},
	},
	
	config = {
		pickup = {
			stowable = true,
			buttonImage = "rbxassetid://5836949301",
		},

		bananaPeel = {
			peelSendMagnitude = 50,
			characterTorqueMagnitude = 150,
			characterVelocityImpulse = Vector3.new(0, 400, 0),
			peelVerticalImpulse = Vector3.new(0, 60, 0),
			peelDebounce = 0.5,
			getUpDelay = 2.0,
			destroyFadeDuration = 0.5,
		},
	},
})
