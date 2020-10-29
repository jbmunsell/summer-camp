--
--	Jackson Munsell
--	20 Aug 2020
--	InstanceTags.lua
--
--	Instance tags enum
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules
local tableau = require(env.packages.axis.lib.tableau)

-- return enum
return tableau.lock({
	FXPart    = "FXPart",
	GhostPart = "GhostPart",

	PlayerCharacter = "PlayerCharacter",

	Activity = "Activity",
	EngagementPoint = "EngagementPoint",
	TravelLocation = "TravelLocation",
	Activities = {
		Soccer    = "Activity_Soccer",
		Smashball = "Activity_Smashball",
	},
})
