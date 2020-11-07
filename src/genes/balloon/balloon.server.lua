--
--	Jackson Munsell
--	13 Oct 2020
--	balloon.server.lua
--
--	Balloon server driver. Places balloon according to client requests,
-- 	and decrease balloon helium over time.
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local pickup = genes.pickup
local balloon = genes.balloon

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local pickupUtil = require(pickup.util)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Request placement
local function attachBalloon(balloonInstance, attachInstance, position)
	-- Strip balloonInstance
	pickupUtil.stripObject(balloonInstance)

	-- Smooth attach balloonInstance to a new attachment
	local stickAttachment = Instance.new("Attachment", attachInstance)
	stickAttachment.Name = "StickAttachment"
	stickAttachment.CFrame = attachInstance.CFrame:toObjectSpace(CFrame.new(position))
	axisUtil.smoothAttach(attachInstance, balloonInstance, "StickAttachment")
end

-- Remove handle mass
-- 	This should be called when equipped to a character
local function removeHandleMass(balloonInstance)
	balloonInstance.Handle.CustomPhysicalProperties = nil
	balloonInstance.Handle.Massless = true	
end

-- Update air resistance based on velocity
local function updateBalloonAirResistance(balloonInstance)
	-- Thank you joe!
	-- Prevent NAAN when zero velocity
	local balloonPart = balloonInstance.Balloon
	local scale = (balloonPart.Size.Y / 6) ^ 3
	local f = balloonPart.Velocity * balloonPart.Velocity + Vector3.new(.01, .01, .01)
	balloonPart.BodyVelocity.MaxForce = f.Unit * math.ceil(f.Magnitude) * scale
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Balloon object stream
local balloonObjectStream = genesUtil.initGene(balloon)

-- Place on request
pickupUtil.getPlayerObjectActionRequestStream(balloon.net.PlacementRequested, balloon)
	:filter(function (_, _, attachInstance)
		return attachInstance
		and attachInstance ~= workspace.Terrain
		and attachInstance:IsDescendantOf(workspace)
	end)
	:map(dart.omitFirst)
	:subscribe(attachBalloon)

-- Update balloon velocity
balloonObjectStream
	:flatMap(function (balloonInstance)
		return rx.Observable.heartbeat()
			:map(dart.constant(balloonInstance))
			:takeUntil(rx.Observable.fromInstanceLeftGame(balloonInstance))
	end)
	:subscribe(updateBalloonAirResistance)

-- Detach balloons after their life expires
-- balloonAddedStream
-- 	:delay(balloonConfig.MaxLife)
-- 	:reject(function (balloon) return balloon:FindFirstChild("NoDetach") end)
-- 	:subscribe(balloonUtil.detachBalloon)

-- When a balloon is moved, destroy it if it's too high
balloonObjectStream
	:flatMap(function (balloonInstance)
		return rx.Observable.fromProperty(balloonInstance.Balloon, "Position")
			:filter(function (position)
				return position.Y > balloonInstance.config.balloon.destroyHeight.Value
			end)
			:map(dart.constant(balloonInstance))
	end)
	:subscribe(dart.destroy)

-- When a balloon is held by a character, make the handle massless
balloonObjectStream
	:flatMap(function (balloonInstance)
		return rx.Observable.from(balloonInstance.state.pickup.holder)
			:filter()
			:map(dart.constant(balloonInstance))
	end)
	:subscribe(removeHandleMass)
