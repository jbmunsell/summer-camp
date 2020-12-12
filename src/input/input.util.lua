--
--	Jackson Munsell
--	22 Oct 2020
--	input.util.lua
--
--	Input util - contains mouse raycasting functions
--

-- env
local UserInputService = game:GetService("UserInputService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)

-- lib
local inputUtil = {}
local raycastParams = RaycastParams.new()
raycastParams.CollisionGroup = "ToolRaycast"

---------------------------------------------------------------------------------------------------
-- Mouse tracking functions
---------------------------------------------------------------------------------------------------

-- Get thumbstick shifts
function inputUtil.getThumbstickXShiftStream(stick)
	return rx.Observable.from(UserInputService.InputChanged)
		:filter(function (input) return input.KeyCode == stick end)
		:map(function (input)
			if input.Position.X <= -0.25 then
				return -1
			elseif input.Position.X >= 0.25 then
				return 1
			else
				return 0
			end
		end)
		:distinctUntilChanged()
end

-- Basic raycast params
-- 	Ignores the basic ignore groups, like fx parts and ghost parts
function inputUtil.getToolRaycastParams()
	return raycastParams
end

-- Raycast mouse
function inputUtil.raycastMouse()
	local mousePosition = UserInputService:GetMouseLocation()
	local ray = workspace.CurrentCamera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
	local dir = ray.Direction * 1000
	local result = workspace:Raycast(ray.Origin, dir, raycastParams)
	return result, ray.Origin + dir
end

-- Get mouse hit
function inputUtil.getMouseHit()
	local result, final = inputUtil.raycastMouse()
	return result and result.Position or final
end

-- return
return inputUtil
