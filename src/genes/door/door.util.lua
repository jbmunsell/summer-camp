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

-- modules
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)

-- lib
local doorUtil = {}

-- Render door
function doorUtil.renderDoor(instance)
	local open = instance.state.door.open.Value
	local config = instance.config.door
	tableau.from(instance:GetDescendants())
		:filter(dart.isa("HingeConstraint"))
		:foreach(function (hinge)
			hinge.TargetAngle = (open and config.openAngle or config.closedAngle).Value
		end)
end

-- return lib
return doorUtil
