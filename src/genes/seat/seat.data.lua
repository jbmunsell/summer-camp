
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

local genesUtil = require(env.src.genes.util)

return genesUtil.createGeneData({
	instanceTag = "gene_seat",
	name = "seat",
	genes = { env.src.genes.humanoidHolder },
})
