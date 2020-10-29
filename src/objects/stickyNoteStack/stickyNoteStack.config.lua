
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local objects = env.src.objects
local objectsUtil = require(objects.util)

return objectsUtil.createObjectConfig({
	instanceTag = "Object_StickyNoteStack",
	className = "stickyNoteStack",
	genes = { objects.pickup },
	state = {
		count = 10,
	},

	pickup = {
		stowable = true,
		buttonImage = "rbxgameasset://Images/StickyNote (1)",
	},

	placementDistanceThreshold = 20, -- Sticky notes cannot be placed beyond this distance (studs) from character
	rotationRange = 6, -- Total degree rotation range of sticky notes (half on each side)

	removeAfterTimer = 0.1 * 60, -- Set to nil to disable this. Value units are SECONDS
	removeAfterOwnerLeft = true, -- Set this to true to remove sticky notes when the player who placed them leaves the game
	destroyAnimationDuration = 1, -- Time taken to fade out and destroy sticky notes that unstick

	stickProtrusion = CFrame.new(0, 0, -0.075),
	stickAngle = CFrame.Angles(math.rad(5), 0, 0),
})
