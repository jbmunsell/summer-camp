
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_mattress",
	name = "mattress",
	genes = { env.src.genes.humanoidHolder },
})
