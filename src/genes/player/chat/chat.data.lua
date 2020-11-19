-- local env = require(game:GetService("ReplicatedStorage").src.env)
-- local genes = env.src.genes

return {
	instanceTag = "gene_chat",
	name = "chat",
	genes = {},
	state = {
		chat = {
			color = Color3.new(1, 1, 1),
		},
	},

	config = {
	},
}
