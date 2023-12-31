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
local genes = env.src.genes

-- modules
local fx = require(axis.lib.fx)
local axisUtil = require(axis.lib.axisUtil)
local soundUtil = require(axis.lib.soundUtil)
local pickupUtil = require(genes.pickup.util)

-- lib
local snowUtil = {}

-- Emit snow particles at point
function snowUtil.emitSnowParticlesAtPosition(position, count, prepare)
	local emitter = env.res.snow.SnowMeltEmitter:Clone()
	emitter.Size = Vector3.new(2, 2, 2)
	emitter.CFrame = CFrame.new(position)
	emitter.Parent = workspace
	soundUtil.playSound(env.res.snow.audio.SnowMelt, emitter)
	if prepare then
		prepare(emitter)
	end
	fx.setFXEnabled(emitter, false)
	fx.emit(emitter, count or 5)
	fx.smoothDestroy(emitter)
end

-- Raycast player ground
function snowUtil.raycastPlayerGround(player, offset)
	local root = axisUtil.getPlayerHumanoidRootPart(player)
	local params = RaycastParams.new()
	params.CollisionGroup = "IndicatorRaycast"
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = pickupUtil.getCharacterHeldObjects(player.Character):raw()
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
