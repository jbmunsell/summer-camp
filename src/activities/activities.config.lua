
local activitiesConfig = {
	smashball = {
		DisplayName = "Smashball",
		teams = {
			dodgers = {
				Color = Purple,
				DisplayName = "Dodgers",
			},
			smashers = {
				Color = Yellow,
				DisplayName = "Smashers",
			}
		}
	},
	
	soccer = {
		DisplayName = "Soccer",
		GoalsToWin = 3,
		teams = createDefaultTeams(),
	},
}

return activitiesConfig
