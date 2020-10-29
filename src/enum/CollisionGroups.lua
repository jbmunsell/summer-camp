--
--	Jackson Munsell
--	03 Oct 2020
--	CollisionGroups.lua
--
--	Collision groups enum
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules
local tableau = require(env.packages.axis.lib.tableau)

-- return enum
return tableau.lock({
	Default    = "Default",
	FXParts    = "FXParts",
	GhostParts = "GhostParts",
})
