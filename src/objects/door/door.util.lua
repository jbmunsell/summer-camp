--
--	Jackson Munsell
--	29 Oct 2020
--	door.util.lua
--
--	Door util
--

-- env
-- local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules

-- lib
local doorUtil = {}

-- Render door
function doorUtil.renderDoor(instance)
	local open = instance.state.door.open.Value
	local hinge = instance:FindFirstChildWhichIsA("HingeConstraint", true)
	hinge.TargetAngle = (open and 90 or 0)
end

-- Toggle door open
function doorUtil.toggleDoorOpen(instance)
	instance.state.door.open.Value = not instance.state.door.open.Value
end

-- return lib
return doorUtil
