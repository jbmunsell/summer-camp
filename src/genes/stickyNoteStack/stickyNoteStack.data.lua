
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genes = env.src.genes
local genesUtil = require(genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_stickyNoteStack",
	name = "stickyNoteStack",
	genes = { genes.pickup, genes.color },
	state = {
		stickyNoteStack = {
			count = 10,
		},
	},

	config = {
		pickup = {
			stowable = true,
			buttonImage = "rbxgameasset://Images/StickyNote (1)",
		},

		stickyNoteStack = {
			count = 5,

			placementDistanceThreshold = 20, -- Sticky notes cannot be placed beyond this distance (studs) from character
			rotationRange = 6, -- Total degree rotation range of sticky notes (half on each side)

			removeAfterTimer = 5 * 60, -- Set to nil to disable this. Value units are SECONDS
			removeAfterOwnerLeft = true, -- Set this to true to remove sticky notes when the player who placed them leaves the game
			destroyAnimationDuration = 1, -- Time taken to fade out and destroy sticky notes that unstick

			stickProtrusion = CFrame.new(0, 0, -0.075),
			stickAngle = CFrame.Angles(math.rad(5), 0, 0),
		},
	},
})
