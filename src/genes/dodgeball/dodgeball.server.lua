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
local dodgeball = genes.dodgeball

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
	ball.state.dodgeball.hot.Value = true
	ball.state.dodgeball.thrower.Value = player.Character

	-- Unequip and launch
	pickupUtil.unequipCharacter(player.Character)
	ball.Velocity = (target - ball.Position).unit * ball.config.dodgeball.throwMagnitude.Value
	ball.Float.Enabled = true
end

-- Handle hot ball touched
local function handleHotBallTouched(ball, hit)
	-- Throw out events where we touched the thrower
	if hit.Parent and hit.Parent == ball.state.dodgeball.thrower.Value then return end
	ball.interface.dodgeball.TouchedNonThrowerPart:Fire(hit)
	ball.state.dodgeball.hot.Value = false
	ball.state.dodgeball.thrower.Value = nil
	ball.state.pickup.enabled.Value = true
	ball.Float.Enabled = false
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Stream representing all dodgeballs
local dodgeballStream = genesUtil.initGene(dodgeball)

-- Throw dodgeball on request
pickupUtil.getPlayerObjectActionRequestStream(dodgeball.net.ThrowRequested, dodgeball)
	:subscribe(throwBall)

-- Cool down hot dodgeballs when they hit something
dodgeballStream
	:flatMap(function (dodgeballInstance)
		return rx.Observable.from(dodgeballInstance.Touched)
			:filter(dart.getValue(dodgeballInstance.state.dodgeball.hot))
			:map(dart.carry(dodgeballInstance))
	end)
	:subscribe(handleHotBallTouched)
