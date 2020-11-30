--
--	Jackson Munsell
--	22 Nov 2020
--	color.util.lua
--
--	color gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

-- lib
local colorUtil = {}

-- init instance
function colorUtil.initInstance(instance)
	-- genesUtil.readConfigIntoState(instance, "color", "color")
	rx.Observable.from(instance.state.color.color)
		:map(dart.carry(instance))
		:subscribe(colorUtil.renderColor)
	-- LEFT OFF HERE
	-- Next trick is going to be monitoring subscription counts
	-- upon deleting an item with just the color subscription
end

-- render color
function colorUtil.renderColor(instance, color)
	for _, d in pairs(instance:GetDescendants()) do
		if d.Name == "autoColorProperty" then
			local h, s, v = color:ToHSV()
			if d:FindFirstChild("valueShift") then
				v = v + d.valueShift.Value
			end

			local alteredColor = Color3.fromHSV(h, s, math.min(math.max(v, 0), 1))
			local propType = typeof(d.Parent[d.Value])
			if propType == "ColorSequence" then
				d.Parent[d.Value] = ColorSequence.new(alteredColor)
			elseif propType == "BrickColor" then
				d.Parent[d.Value] = BrickColor.new(alteredColor)
			else
				d.Parent[d.Value] = alteredColor
			end
		end
	end
end

-- return lib
return colorUtil
