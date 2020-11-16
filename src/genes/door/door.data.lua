
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	instanceTag = "gene_door",
	name = "door",
	genes = { env.src.genes.interact },
	state = {
		door = {
			open = false,
		},
	},

	config = {
		door = {
			closedAngle = 0,
			openAngle = 90,
		},
	},
}
