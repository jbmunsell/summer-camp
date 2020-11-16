
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	instanceTag = "gene_seat",
	name = "seat",
	genes = { env.src.genes.humanoidHolder },
}
