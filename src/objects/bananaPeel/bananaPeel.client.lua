--
--	Jackson Munsell
--	15 Oct 2020
--	bananaPeel.client.lua
--
--	Banana peel object client driver. Listens for server
-- 	slip request, then ragdolls and applies velocity impulse.
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local ragdoll = env.src.ragdoll
local bananaPeel = env.src.objects.bananaPeel

-- modules
local rx = require(axis.lib.rx)
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local bananaPeelConfig = require(bananaPeel.config)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Slip
local function slip(peel)
	-- Ragdoll
	ragdoll.interface.PushRagdoll:Invoke()

	-- Calculate throw and torque angles
	local throwAngle = math.random() * math.pi * 2
	local torqueAngle = throwAngle + math.pi * 0.5
	local throwUnit = Vector3.new(math.cos(throwAngle), 0, math.sin(throwAngle))
	local torqueUnit = Vector3.new(math.cos(torqueAngle), 0, math.sin(torqueAngle))

	-- Apply impulses to character and banana peel
	local character = env.LocalPlayer.Character
	axisUtil.applyCharacterVelocityImpulse(character, bananaPeelConfig.characterVelocityImpulse)
	axisUtil.applyCharacterRotationImpulse(character, torqueUnit * bananaPeelConfig.characterTorqueMagnitude)
	if peel:IsDescendantOf(game) then
		peel.PrimaryPart.Velocity = throwUnit * bananaPeelConfig.peelSendMagnitude + bananaPeelConfig.peelVerticalImpulse
	end
end

-- Get up
local function getUp()
	ragdoll.interface.PopRagdoll:Invoke()
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Peel slip request
local slipStream = rx.Observable.from(bananaPeel.net.Slipped)

-- Slip
slipStream
	:subscribe(slip)

-- Get up
slipStream
	:delay(bananaPeelConfig.getUpDelay)
	:subscribe(getUp)

-- Destroy banana peel
rx.Observable.from(bananaPeel.net.Destroyed)
	:map(dart.drag(bananaPeelConfig.destroyFadeDuration))
	:subscribe(fx.fadeOutAndDestroy)
