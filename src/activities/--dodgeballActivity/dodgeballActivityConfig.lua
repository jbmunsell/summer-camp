
local env = require(game:GetService("ReplicatedStorage").src.env)

local activitiesUtil = require(env.src.activities.util)

return {
	instanceTag = "Activity_Dodgeball",
	displayName = "Dodgeball",
	teams = activitiesUtil.createDefaultTeams(),
}

