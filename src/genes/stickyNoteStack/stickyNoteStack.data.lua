
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local genes = env.src.genes

return {
	instanceTag = "gene_stickyNoteStack",
	name = "stickyNoteStack",
	genes = { genes.worldAttach, genes.textConfigure },
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

		worldAttach = {
			count = 10,

			attachSound = env.res.genes.stickyNoteStack.sounds.PageTurn,
		},
	},
}
