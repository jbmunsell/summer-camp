
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	instanceTag = "gene_mattress",
	name = "mattress",
	genes = { env.src.genes.humanoidHolder },
}
