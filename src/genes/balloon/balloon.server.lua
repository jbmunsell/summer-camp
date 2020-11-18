--
--	Jackson Munsell
--	13 Oct 2020
--	balloon.server.lua
--
--	Balloon server driver. Places balloon according to client requests,
-- 	and decrease balloon helium over time.
--

-- env
local Players = game:GetService("Players")
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
local multiswitchUtil = require(genes.multiswitch.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Request placement
local function attachBalloon(balloonInstance, attachInstance, position)
	-- Strip balloonInstance
	pickupUtil.stripObject(balloonInstance)

	-- Flip switch
	multiswitchUtil.setSwitchEnabled(balloonInstance, "interact", "balloon", false)

	-- Place it in the character if it's a descendant
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and attachInstance:IsDescendantOf(player.Character) then
			balloonInstance.Parent = player.Character
		end
	end

	-- Smooth attach balloonInstance to a new attachment
	local stickAttachment = Instance.new("Attachment", attachInstance)
	stickAttachment.Name = "StickAttachment"
	stickAttachment.CFrame = attachInstance.CFrame:toObjectSpace(CFrame.new(position))
	local weld = axisUtil.smoothAttach(attachInstance, balloonInstance, "StickAttachment")
	weld.Name = "BalloonAttachWeld"
	weld.Parent = balloonInstance

	-- Detach after time
	rx.Observable.timer(balloonInstance.config.balloon.lifetime.Value)
		:subscribe(dart.bind(axisUtil.destroyChild, balloonInstance, "BalloonAttachWeld"))
end

-- Remove handle mass
-- 	This should be called when equipped to a character
local function removeHandleMass(balloonInstance)
	balloonInstance.Handle.CustomPhysicalProperties = nil
	balloonInstance.Handle.Massless = true	
end

-- Update air resistance based on velocity
local resistanceFloor = Vector3.new(.01, .01, .01)
local function updateBalloonAirResistance(balloonInstance)
	-- Thank you joe!
	-- Prevent NAAN when zero velocity
	local balloonPart = balloonInstance.Balloon
	local scale = (balloonPart.Size.Y / 6) ^ 3
	local f = balloonPart.Velocity * balloonPart.Velocity + resistanceFloor
	balloonPart.BodyVelocity.MaxForce = f.Unit * math.ceil(f.Magnitude) * scale
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Balloon object stream
local balloonObjectStream = genesUtil.initGene(balloon)

-- Render color
genesUtil.crossObserveStateValue(balloon, genes.color, "color"):subscribe(function (instance, color)
	instance.Balloon.Color = color
end)

-- Place on request
pickupUtil.getPlayerObjectActionRequestStream(balloon.net.PlacementRequested, balloon)
	:filter(function (_, _, attachInstance)
		return attachInstance
		and attachInstance ~= workspace.Terrain
		and attachInstance:IsDescendantOf(workspace)
	end)
	:map(dart.drop(1))
	:subscribe(attachBalloon)

-- Update balloon velocity
balloonObjectStream:subscribe(function (instance)
	rx.Observable.fromProperty(instance.Balloon, "Position")
		:subscribe(dart.bind(updateBalloonAirResistance, instance))
end)

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
genesUtil.crossObserveStateValue(balloon, pickup, "holder")
	:filter(dart.select(2))
	:subscribe(removeHandleMass)
