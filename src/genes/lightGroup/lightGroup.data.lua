
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

return {
	instanceTag = "gene_lightGroup",
	name = "lightGroup",
	genes = { env.src.genes.interact },
	state = {
		lightGroup = {
			switches = {
				primary = false,
			},
		},
	},
}
