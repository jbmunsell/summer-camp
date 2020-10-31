--
--	Jackson Munsell
--	07 Sep 2020
--	lightGroup.server.lua
--
--	Light group interactable server functionality driver
--

-- env
local env  = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local interact = genes.interact
local lightGroup = genes.lightGroup

-- modules
local rx = require(axis.lib.rx)
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local genesUtil = require(genes.util)
local interactUtil = require(interact.util)

-- set state
local function renderLightGroup(instance)
	-- Enable light objects
	local enabled = instance.state.lightGroup.enabled.Value
	fx.setFXEnabled(instance, enabled)

	-- Set switch model mode (up when on, down when off)
	local folderName = (enabled and "lightPartOnProperties" or "lightPartOffProperties")
	local properties = instance:FindFirstChild(folderName)
	if properties then
		tableau.from(instance:GetDescendants())
			:filter(dart.isa("Light"))
			:map(dart.index("Parent"))
			:filter(dart.isa("BasePart"))
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

-- init light group
local function initLightGroup(instance)
	rx.Observable.from(instance.state.lightGroup.enabled)
		:map(dart.constant(instance))
		:subscribe(renderLightGroup)
end

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Toggle state
local function toggleLightGroupState(group)
	group.state.lightGroup.enabled.Value = not group.state.lightGroup.enabled.Value
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Connect to all light groups forever
genesUtil.initGene(lightGroup):subscribe(initLightGroup)

-- Light group interacted
interactUtil.getInteractStream(lightGroup)
	:map(dart.omitFirst)
	:subscribe(toggleLightGroupState)
