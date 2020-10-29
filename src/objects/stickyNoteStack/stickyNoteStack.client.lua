--
--	Jackson Munsell
--	20 Oct 2020
--	stickyNoteStack.client.lua
--
--	Sticky note stack client driver. Places on click.
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local input = env.src.input
local pickup = env.src.objects.pickup
local stickyNoteStack = env.src.objects.stickyNoteStack

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local inputUtil = require(input.util)
local pickupUtil = require(pickup.util)
local stickyNoteStackConfig = require(stickyNoteStack.config)
local stickyNoteStackUtil = require(stickyNoteStack.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

-- Rotation (changed each time the user equips sticky note stack)
local rotation = 0
local stickyNoteText = "jackson!"

-- Sticky note preview
-- 	Parent is set to show and hide when there is a sticky note equipped
local preview = env.res.objects.StickyNote:Clone()
stickyNoteStackUtil.tagNote(preview)
stickyNoteStackUtil.setNoteText(preview, stickyNoteText)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- New preview rotation
local function newRotation()
	rotation = (math.random() - 0.5) * stickyNoteStackConfig.rotationRange
end

-- Set preview enabled
local function setPreviewEnabled(enabled)
	preview.Parent = (enabled and workspace or ReplicatedStorage)
end

-- Package raycast data
local function packageRaycastData(raycastResult)
	return raycastResult and {
		instance = raycastResult.Instance,
		position = raycastResult.Position,
		normal = raycastResult.Normal,
		rotation = rotation,
	}
end

-- Place preview
local function placePreview(raycastData)
	local distance = (raycastData.position and env.LocalPlayer:DistanceFromCharacter(raycastData.position) or 0)
	if not raycastData.instance
	or distance == 0
	or distance >= stickyNoteStackConfig.placementDistanceThreshold then
		setPreviewEnabled(false)
		return
	else
		setPreviewEnabled(true)
	end
	preview.CFrame = stickyNoteStackUtil.getWorldCFrame(raycastData)
		:toWorldSpace(preview.StickAttachment.CFrame:inverse())
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Bind preview to holding or not
local holdingStream = pickupUtil.getLocalCharacterHoldingStream(stickyNoteStack)
holdingStream
	:subscribe(setPreviewEnabled)
holdingStream
	:filter()
	:subscribe(newRotation)

-- Bind preview update on mouse move
rx.Observable.heartbeat()
	:withLatestFrom(holdingStream)
	:filter(function (_, holding)
		return holding
	end)
	:map(function ()
		return packageRaycastData(inputUtil.raycastMouse())
	end)
	:filter()
	:subscribe(placePreview)

-- Bind click
pickupUtil.getClickWhileHoldingStream(stickyNoteStack)
	:map(function ()
		return packageRaycastData(inputUtil.raycastMouse()), stickyNoteText
	end)
	:filter()
	:subscribe(dart.forward(stickyNoteStack.net.PlacementRequested))
	