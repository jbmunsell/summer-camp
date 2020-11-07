
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_daytimeSwitch",
	name = "daytimeSwitch",
	genes = { env.src.genes.multiswitch.timeOfDaySwitch },
	config = {
		timeOfDaySwitch = {
			switchOnTime = 8.0,
			switchOffTime = 18.0,
		},
	},
})
