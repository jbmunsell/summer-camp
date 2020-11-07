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
local genes = env.src.genes
local bananaPeel = genes.bananaPeel

-- modules
local rx = require(axis.lib.rx)
local fx = require(axis.lib.fx)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)

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
	local config = peel.config.bananaPeel
	local character = env.LocalPlayer.Character
	axisUtil.applyCharacterVelocityImpulse(character, config.characterVelocityImpulse.Value)
	axisUtil.applyCharacterRotationImpulse(character, torqueUnit * config.characterTorqueMagnitude.Value)
	if peel:IsDescendantOf(game) then
		peel.PrimaryPart.Velocity = throwUnit * config.peelSendMagnitude.Value + config.peelVerticalImpulse.Value
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
	:delay(function (peel)
		return peel.config.bananaPeel.getUpDelay.Value
	end)
	:subscribe(getUp)

-- Destroy banana peel
rx.Observable.from(bananaPeel.net.Destroyed)
	:map(function (peel)
		return peel, peel.config.bananaPeel.destroyFadeDuration.Value
	end)
	:subscribe(fx.fadeOutAndDestroy)
