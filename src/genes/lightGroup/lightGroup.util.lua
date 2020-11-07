--
--	Jackson Munsell
--	06 Nov 2020
--	lightGroup.util.lua
--
--	lightGroup gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local multiswitch = env.src.genes.multiswitch

-- modules
local rx = require(axis.lib.rx)
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local multiswitchUtil = require(multiswitch.util)

-- lib
local lightGroupUtil = {}

-- Render light group according to all of its switches
function lightGroupUtil.renderLightGroup(instance)
	-- Enable light objects
	local enabled = multiswitchUtil.all(instance, "lightGroup")
	fx.setFXEnabled(instance, enabled)

	-- Set switch model mode (up when on, down when off)
	local folderName = (enabled and "lightPartOnProperties" or "lightPartOffProperties")
	local properties = instance:FindFirstChild(folderName)
	if properties then
		tableau.from(instance:GetDescendants())
			:filter(dart.isa("Light"))
			:map(dart.index("Parent"))
			:map(function (parent)
				return parent:IsA("Attachment") and parent.Parent or parent
			end)
			:foreach(function (part)
				for _, valueObject in pairs(properties:GetChildren()) do
					part[valueObject.Name] = valueObject.Value
				end
			end)
		end
	rx.Observable.from(instance:GetDescendants())
		:map(function (c)
			return c, (c.Name == "SwitchOn" and 1 or (c.Name == "SwitchOff" and 0))
		end)
		:filter(function (_, v) return v end)
		:subscribe(function (c, v)
			c.Transparency = (enabled and 1 - v or v)
		end)
end


-- return lib
return lightGroupUtil
