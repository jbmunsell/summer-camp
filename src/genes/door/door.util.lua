--
--	Jackson Munsell
--	29 Oct 2020
--	door.util.lua
--
--	Door util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local genesUtil = require(genes.util)

-- lib
local doorUtil = {}

-- Render door
function doorUtil.renderDoor(instance)
	local open = instance.state.door.open.Value
	local config = genesUtil.getConfig(instance).door
	tableau.from(instance:GetDescendants())
		:filter(dart.isa("HingeConstraint"))
		:foreach(function (hinge)
			hinge.TargetAngle = (open and config.openAngle or config.closedAngle)
		end)
end

-- Toggle door open
function doorUtil.toggleDoorOpen(instance)
	instance.state.door.open.Value = not instance.state.door.open.Value
end

-- return lib
return doorUtil
