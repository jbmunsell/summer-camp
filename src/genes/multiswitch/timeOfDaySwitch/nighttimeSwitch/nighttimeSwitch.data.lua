
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	instanceTag = "gene_nighttimeSwitch",
	name = "nighttimeSwitch",
	genes = { env.src.genes.multiswitch.timeOfDaySwitch },
	config = {
		timeOfDaySwitch = {
			switchOnTime = 18.0,
			switchOffTime = 8.0,
		},
	},
}
