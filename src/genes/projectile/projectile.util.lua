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

-- lib
local projectileUtil = {}

-- Fire projectile
function projectileUtil.rootFireProjectile(instance, start, target, velocityMagnitude, owned)
	-- Folders
	print("root firing")
	assert(instance:IsA("Model"), "projectile gene only works with models")
	local config = instance.config.projectile
	local interface = instance.interface.projectile
	local primary = instance.PrimaryPart
	instance.state.projectile.velocityMagnitude.Value = velocityMagnitude

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

	-- Pulse
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
		local last = instance:GetPrimaryPartCFrame().p
		local new = last + velocity * dt

		-- Raycast to see if we hit something
		if owned then
			local result = workspace:Raycast(last, (new - last), params)
			if result and result.Instance then
				new = result.Position
				interface.RemoteHit:FireServer(result.Instance, result.Position)
				interface.LocalHit:Fire(result.Instance, result.Position)
			end
		end

		-- Set CFrame
		instance:SetPrimaryPartCFrame(CFrame.new(new, new + (new - last)))
	end)
end
function projectileUtil.fireOwnedProjectile(instance, start, target, velocity)
	projectileUtil.rootFireProjectile(instance, start, target, velocity, true)
end
function projectileUtil.fireProjectile(instance, start, target, velocity)
	projectileUtil.rootFireProjectile(instance, start, target, velocity, false)
end

-- return lib
return projectileUtil
