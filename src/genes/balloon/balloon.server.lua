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

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local pickupUtil = require(pickup.util)
local genesUtil = require(genes.util)
local multiswitchUtil = require(genes.multiswitch.util)
local balloonData = require(genes.balloon.data)

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
	local weld = axisUtil.smoothAttachAttachments(attachInstance, stickAttachment, balloonInstance, "StickAttachment")
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
genesUtil.initGene(genes.balloon)

-- Place on request
pickupUtil.getPlayerObjectActionRequestStream(genes.balloon.net.PlacementRequested, genes.balloon)
	:filter(function (_, _, attachInstance)
		return attachInstance
		and attachInstance ~= workspace.Terrain
		and attachInstance:IsDescendantOf(workspace)
	end)
	:map(dart.drop(1))
	:subscribe(attachBalloon)

-- Update balloon velocity
local destroyHeight = balloonData.config.balloon.destroyHeight
local balloons = genesUtil.getInstances(genes.balloon):raw()
rx.Observable.heartbeat():subscribe(function ()
	for _, balloonInstance in pairs(balloons) do
		updateBalloonAirResistance(balloonInstance)
		if balloonInstance.Balloon.Position.Y > destroyHeight then
			balloonInstance:Destroy()
		end
	end
end)

-- When a balloon is held by a character, make the handle massless
-- genesUtil.crossObserveStateValue(genes.balloon, pickup, "holder")
-- 	:filter(dart.select(2))
-- 	:subscribe(removeHandleMass)
