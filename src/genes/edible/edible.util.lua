--
--	Jackson Munsell
--	01 Nov 2020
--	edible.util.lua
--
--	Edible gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)

-- lib
local edibleUtil = {}

-- Eat food
function edibleUtil.isEaten(instance)
	return instance.state.edible.eaten.Value
end
function edibleUtil.eat(instance)
	-- Set state value
	instance.state.edible.eaten.Value = true

	-- Create sound if it doesn't exist
	local sound = instance:FindFirstChild("EatSound", true)
	if not sound then
		sound = env.res.dining.EatSound:Clone()
		sound.Parent = (instance:IsA("BasePart") and instance or instance.PrimaryPart)
		if not sound.Parent then
			warn("Attempt to play eat sound in an edible model with no PrimaryPart")
			return
		end
	end
	sound:Play()

	-- Fade out all non-dish parts
	tableau.from(instance:GetDescendants())
		:append({ instance })
		:filter(dart.isa("BasePart"))
		:reject(dart.isNamed("DishPart"))
		:foreach(fx.fadeOutAndDestroy)
end

-- return lib
return edibleUtil
