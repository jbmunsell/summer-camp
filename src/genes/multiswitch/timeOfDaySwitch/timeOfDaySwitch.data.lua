
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_timeOfDaySwitch",
	name = "timeOfDaySwitch",
	genes = {},
	config = {
		timeOfDaySwitch = {
			switchOnTime = 6.0,
			switchOffTime = 20.0,
		},
	},
})
