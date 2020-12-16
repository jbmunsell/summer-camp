--
--	Jackson Munsell
--	14 Dec 2020
--	snow.util.lua
--
--	snow gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local axisUtil = require(axis.lib.axisUtil)

-- lib
local snowUtil = {}

-- Raycast player ground
function snowUtil.raycastPlayerGround(player, offset)
	local root = axisUtil.getPlayerHumanoidRootPart(player)
	local params = RaycastParams.new()
	params.CollisionGroup = "IndicatorRaycast"
	return root and workspace:Raycast((root.CFrame * (offset or CFrame.new())).p, Vector3.new(0, -10, 0), params)
end

-- is standing on snow
function snowUtil.isPlayerStandingOnSnow(player)
	local result = snowUtil.raycastPlayerGround(player)
	return result and result.Material == Enum.Material.Snow
end

-- get player standing position
function snowUtil.getPlayerStandingPosition(player)
	local result = snowUtil.raycastPlayerGround(player)
	return result and result.Position
end

-- return lib
return snowUtil