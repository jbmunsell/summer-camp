--
--	Jackson Munsell
--	15 Dec 2020
--	projectile.util.lua
--
--	projectile gene util
--

-- env
local RunService = game:GetService("RunService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local soundUtil = require(axis.lib.soundUtil)

-- lib
local projectileUtil = {}

-- Fire projectile
function projectileUtil.rootFireProjectile(thrower, instance, start, target, velocityMagnitude, owned)
	-- Folders
	assert(instance:IsA("Model"), "projectile gene only works with models")
	local config = instance.config.projectile
	local interface = instance.interface.projectile
	local state = instance.state.projectile
	local primary = instance.PrimaryPart
	instance.state.projectile.velocityMagnitude.Value = velocityMagnitude

	-- Play sound
	local sound = instance.config.projectile.launchSound.Value
	if sound then
		soundUtil.playSound(sound, axisUtil.getPlayerHumanoidRootPart(thrower))
	end

	-- Raycast params
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { instance, env.LocalPlayer.Character }

	-- Start it out
	local floatForce = config.floatForceProportion.Value
	local velocity = (target - start).unit * velocityMagnitude
	primary.Anchored = true
	primary.CanCollide = false
	instance:SetPrimaryPartCFrame(CFrame.new(start, target))
	state.launched.Value = true
	instance.interface.projectile.LocalThrown:Fire(thrower, start, target, velocity)

	-- Pulse
	local offsets = {
		CFrame.new(0, 0, 0),
		CFrame.new(-primary.Size.X * 0.4, 0, 0),
		CFrame.new(primary.Size.X * 0.4, 0, 0),
		CFrame.new(0, primary.Size.Y * 0.4, 0),
		CFrame.new(0, -primary.Size.Y * 0.4, 0),
	}
	if not owned then
		rx.Observable.from(interface.RemoteHit):subscribe(dart.forward(interface.LocalHit))
	end
	local terminator = rx.Observable.from(interface.LocalHit)
		:merge(rx.Observable.fromInstanceLeftGame(instance))
		:first()
	rx.Observable.from(RunService.Stepped):map(dart.select(2)):takeUntil(terminator):subscribe(function (dt)
		-- Gravity
		velocity = velocity + Vector3.new(0, -workspace.Gravity * (1 - floatForce) * dt, 0)

		-- Position
		local last = instance:GetPrimaryPartCFrame()
		local new = last + velocity * dt
		local delta = new - last.p

		-- Raycast to see if we hit something
		if owned then
			for _, offset in pairs(offsets) do
				local result = workspace:Raycast(last:toWorldSpace(offset).p, delta:toWorldSpace(offset).p, params)
				if result and result.Instance then
					new = new - new.p + result.Position
					new = new:toWorldSpace(offset:inverse())
					interface.RemoteHit:FireServer(result.Instance, result.Position)
					interface.LocalHit:Fire(result.Instance, result.Position)
					break
				end
			end
		end

		-- Set CFrame
		instance:SetPrimaryPartCFrame(CFrame.new(new.p, new.p + delta.p))
	end)
end
function projectileUtil.fireOwnedProjectile(instance, start, target, velocity)
	projectileUtil.rootFireProjectile(env.LocalPlayer, instance, start, target, velocity, true)
end
function projectileUtil.fireProjectile(thrower, instance, start, target, velocity)
	print("firing unowned projectile")
	projectileUtil.rootFireProjectile(thrower, instance, start, target, velocity, false)
end

-- return lib
return projectileUtil
