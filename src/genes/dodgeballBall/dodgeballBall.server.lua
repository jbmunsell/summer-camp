--
--	Jackson Munsell
--	19 Oct 2020
--	dodgeball.server.lua
--
--	New pickup dodgeball server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local pickup = genes.pickup
local dodgeballBall = genes.dodgeballBall

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local pickupUtil = require(pickup.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Throw ball
-- 	Releases a ball, applies velocity impulse, and sets hot value to true
local function throwBall(player, ball, target)
	-- Set important state values
	ball.state.pickup.enabled.Value = false
	ball.state.dodgeballBall.hot.Value = true
	ball.state.dodgeballBall.thrower.Value = player.Character

	-- Unequip and launch
	pickupUtil.unequipCharacter(player.Character)
	ball.Velocity = (target - ball.Position).unit * ball.config.dodgeballBall.throwMagnitude.Value
	ball.Float.Enabled = true
end

-- Handle hot ball touched
local function handleHotBallTouched(ball, hit)
	-- Throw out events where we touched the thrower
	local thrower = ball.state.dodgeballBall.thrower.Value
	if thrower and hit:IsDescendantOf(thrower) then return end
	ball.interface.dodgeballBall.TouchedNonThrowerPart:Fire(hit)
	ball.state.dodgeballBall.hot.Value = false
	ball.state.dodgeballBall.thrower.Value = nil
	ball.state.pickup.enabled.Value = true
	ball.Float.Enabled = false
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Stream representing all dodgeballs
local dodgeballStream = genesUtil.initGene(dodgeballBall)

-- Render color
genesUtil.crossObserveStateValue(dodgeballBall, genes.color, "color")
	:subscribe(function (instance, color)
		instance.Color = color
	end)

-- Throw dodgeballBall on request
pickupUtil.getPlayerObjectActionRequestStream(dodgeballBall.net.ThrowRequested, dodgeballBall)
	:subscribe(throwBall)

-- Cool down hot dodgeballs when they hit something
dodgeballStream
	:flatMap(function (dodgeballInstance)
		return rx.Observable.from(dodgeballInstance.Touched)
			:filter(function () return dodgeballInstance:IsDescendantOf(game) end)
			:filter(function () return dodgeballInstance.state.dodgeballBall.hot.Value end)
			:map(dart.carry(dodgeballInstance))
	end)
	:subscribe(handleHotBallTouched)
