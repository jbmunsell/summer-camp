--
--	Jackson Munsell
--	24 Nov 2020
--	stunDarts.util.lua
--
--	stunDarts gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local ragdoll = env.src.ragdoll

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)

-- lib
local stunDartsUtil = {}

-- Stun and affix
function stunDartsUtil.stunAndAffix(projectile, result)
	-- First, affix
	local cleanup = rx.Observable.timer(3)
	local weld = Instance.new("Weld")
	weld.C0 = result.Instance.CFrame:toObjectSpace(projectile.CFrame - projectile.CFrame.p + result.Position)
	weld.Part0 = result.Instance
	weld.Part1 = projectile
	weld.Parent = projectile
	cleanup:map(dart.constant(projectile)):subscribe(dart.destroy)

	-- Second, try stunning if player character
	local player = axisUtil.getPlayerFromCharacterDescendant(result.Instance)
	if not player then return end
	local character = player.Character
	ragdoll.net.Push:FireClient(player)
	cleanup
		:filter(function () return player.Character == character end)
		:tap(print)
		:map(dart.constant(player))
		:subscribe(dart.forward(ragdoll.net.Pop))
end

-- fire dart
function stunDartsUtil.fireDart(character, shooterInstance, origin, target)
	local config = shooterInstance.config.stunDarts
	local projectile = config.projectile.Value:Clone()
	local unit = (target - origin).unit
	projectile.CFrame = CFrame.new(origin + unit * 2, target)
	projectile.Velocity = unit * config.shootMagnitude.Value
	projectile.Parent = workspace

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { character, shooterInstance }
	rx.Observable.heartbeat():map(function (dt)
		local jump = projectile.Velocity * dt
		return workspace:Raycast(projectile.Position, jump, params)
	end):filter(function (result)
		return result and result.Instance
	end):first():subscribe(dart.bind(stunDartsUtil.stunAndAffix, projectile))
end

-- return lib
return stunDartsUtil
