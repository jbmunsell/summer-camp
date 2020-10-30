local interactConfig = {
	instanceTag = "Interactable",
	className = "interact",
	state = {
		enabledServer = true,
		enabledClient = true,
		locks = {},
	},

	distanceThreshold = 40,
	duration = 0.3,
}

return interactConfig
