
-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local tableau = require(env.packages.axis.lib.tableau)

return {
	instanceTag = "gene_canvas",
	name = "canvas",
	genes = { env.src.genes.interact },
	state = {
		canvas = {
			owner = tableau.null,
			locked = false,
			editing = false, -- For use on client to connect to tools and such
		},
		
		interact = {
			switches = {
				canvas = true,
			},
		},
	},

	config = {
		canvas = {
			collaborative = false,
			activeToolHighlightColor = Color3.fromRGB(190, 145, 255),
			drawingDistance = 20,
		},
	},
}
