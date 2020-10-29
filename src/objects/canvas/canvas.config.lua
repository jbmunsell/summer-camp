
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

local objectsUtil = require(env.src.objects.util)

return objectsUtil.createObjectConfig({
	instanceTag = "Object_Canvas",
	className = "canvas",
	genes = { env.src.interact },
	state = {
		owner = tableau.null,
		teamToAcceptFrom = tableau.null,
		locked = false,
	},

	activeToolHighlightColor = Color3.fromRGB(190, 145, 255),
})
