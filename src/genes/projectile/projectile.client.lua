--
--	Jackson Munsell
--	15 Dec 2020
--	projectile.client.lua
--
--	projectile gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local inputUtil = require(env.src.input.util)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)
local projectileUtil = require(genes.projectile.util)

local projectileAnimations = env.res.genes.projectile.animations

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function playChargeAnimation(instance)
	local animator = axisUtil.getLocalAnimator()
	if not animator then return end
	local anim = env.res.genes.projectile.animations.ChargeThrow
	local chargeTime = instance.config.projectile.chargeTime.Value
	local track = animator:LoadAnimation(anim)
	while track.Length == 0 do wait() end -- Prevent nans from not fully loaded anims
	rx.Observable.from(track:GetMarkerReachedSignal("FullChargeReached"))
		:first()
		:takeUntil(rx.Observable.from(track.Stopped))
		:subscribe(function ()
			animator:LoadAnimation(projectileAnimations.FullChargeHold):Play()
		end)
	track:Play(nil, nil, track.Length / chargeTime)
end

local function throw(instance, chargeProportion, target)
	-- Variables
	local config = instance.config.projectile
	local start = axisUtil.getPosition(instance)
	local vx = math.clamp(chargeProportion, 0, 1)
	local velocity = config.maxThrowVelocity.Value * vx + config.minThrowVelocity.Value * (1 - vx)

	-- Projectile firing
	local function fireProjectile()
		genes.projectile.net.ReleaseRequested:FireServer(instance, start, target, velocity)
		pickupUtil.stripObject(instance)
		projectileUtil.fireOwnedProjectile(instance, start, target, velocity)
	end

	-- Stop charge anim and play throw anim
	local animator = axisUtil.getLocalAnimator()
	if not animator then return end
	local throwTrack = animator:LoadAnimation(projectileAnimations.Throw)
	rx.Observable.from(throwTrack:GetMarkerReachedSignal("Throw"))
		:first()
		:takeUntil(rx.Observable.from(throwTrack.Stopped))
		:subscribe(fireProjectile)
	throwTrack:Play()
	axisUtil.stopAnimationTrack(animator, projectileAnimations.ChargeThrow)
	axisUtil.stopAnimationTrack(animator, projectileAnimations.FullChargeHold)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local projectiles = genesUtil.initGene(genes.projectile)

-- Play charge animation according to projectile charging
pickupUtil.getLocalCharacterHoldingStream(genes.projectile):switchMap(function (instance)
	return instance
	and rx.Observable.from(instance.state.projectile.charging):filter():map(dart.constant(instance))
	or rx.Observable.never()
end):subscribe(playChargeAnimation)

-- Charge that baby up
projectiles:flatMap(function (instance)
	return rx.Observable.from(instance.state.projectile.charging):switchMap(function (charging)
		return charging and rx.Observable.heartbeat() or rx.Observable.never()
	end):map(dart.carry(instance))
end):subscribe(function (instance, dt)
	local chargeTime = instance.state.projectile.chargeTime
	chargeTime.Value = chargeTime.Value + dt
end)

-- When a projectile stops charging, send to server
projectiles:flatMap(function (instance)
	-- Use .Changed to skip the first one (starts out not charging but we shouldn't
	-- 	fire the projectile immediately)
	local state = instance.state.projectile
	local config = instance.config.projectile
	return rx.Observable.from(state.charging.Changed):reject()
		:map(function ()
			return instance,
				state.chargeTime.Value / config.chargeTime.Value,
				inputUtil.getMouseHit()
		end)
end):subscribe(throw)

-- Get pickup stream
pickupUtil.getActivatedStream(genes.projectile):subscribe(function (instance, input)
	if instance.config.projectile.chargeable.Value then
		local charging = instance.state.projectile.charging
		charging.Value = true
		rx.Observable.fromProperty(input, "UserInputState")
			:filter(dart.equals(Enum.UserInputState.End))
			:first()
			:subscribe(function ()
				charging.Value = false
			end)
	else
		warn("Unchargeable projectiles not yet implemented")
	end
end)

-- Fire projectiles when the server tells us to
rx.Observable.from(genes.projectile.net.ProjectileFired)
	:reject(dart.equals(env.LocalPlayer)) -- don't re-fire our own projectiles
	:subscribe(projectileUtil.fireProjectile)
