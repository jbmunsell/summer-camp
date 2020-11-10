--
--	Jackson Munsell
--	20 Oct 2020
--	stickyNoteStack.client.lua
--
--	Sticky note stack client driver. Places on click.
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local input = env.src.input
local genes = env.src.genes
local pickup = genes.pickup
local stickyNoteStack = genes.stickyNoteStack

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local inputUtil = require(input.util)
local pickupUtil = require(pickup.util)
local stickyNoteStackUtil = require(stickyNoteStack.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

-- Rotation (changed each time the user equips sticky note stack)
local rotation = 0
local preview
local gui = env.PlayerGui:WaitForChild("Core").Container.TextPlacementObject
local textInput = gui:FindFirstChild("Input", true)

-- Set initial text according to input type
do
	local initText = string.format("%s to edit text.", (UserInputService.TouchEnabled and "Touch" or "Click"))
	gui:FindFirstChildWhichIsA("TextBox", true).Text = initText
end

-- Sticky note preview
-- 	Parent is set to show and hide when there is a sticky note equipped
-- local preview = env.res.genes.StickyNote:Clone()
-- stickyNoteStackUtil.tagNote(preview)
-- stickyNoteStackUtil.setNoteText(preview, stickyNoteText)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Set gui visible
local function setGuiVisible(visible)
	gui.Visible = visible
end

-- Get gui text
local function getGuiText()
	return textInput.Text
end

-- set preview text
local function setPreviewText(text)
	if preview then
		stickyNoteStackUtil.setNoteText(preview, text)
	end
end

-- Update preview
local function updatePreview(stack)
	if preview then
		preview:Destroy()
		preview = nil
	end
	if stack then
		preview = stack:Clone()
		stickyNoteStackUtil.removeTags(preview)
		stickyNoteStackUtil.tagNote(preview)
		rotation = (math.random() - 0.5) * stack.config.stickyNoteStack.rotationRange.Value
		setPreviewText(textInput.Text)
	end
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
local function placePreview(raycastData, stack)
	local distance = (raycastData.position and env.LocalPlayer:DistanceFromCharacter(raycastData.position) or 0)
	if not raycastData.instance
	or distance == 0
	or distance >= stack.config.stickyNoteStack.placementDistanceThreshold.Value then
		preview.Parent = ReplicatedStorage
		return
	else
		preview.Parent = workspace
	end
	local worldCFrame = stickyNoteStackUtil.getWorldCFrame(stack, raycastData)
	local stickAttachment = stickyNoteStackUtil.getStickAttachment(preview)
	if preview:IsA("BasePart") then
		preview.CFrame = worldCFrame:toWorldSpace(stickAttachment.CFrame:inverse())
	elseif preview:IsA("Model") then
		preview:SetPrimaryPartCFrame(
			worldCFrame:toWorldSpace(stickAttachment.WorldCFrame:toObjectSpace(preview:GetPrimaryPartCFrame()))
		)
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Heartbeat mapped to held stack
local holdingStream = rx.Observable.heartbeat()
	:map(function ()
		return pickupUtil.localCharacterHoldsObject(stickyNoteStack)
	end)

-- Recreate or destroy preview when holding stack changes
holdingStream
	:distinctUntilChanged()
	:subscribe(updatePreview)
holdingStream
	:map(dart.boolify)
	:distinctUntilChanged()
	:subscribe(setGuiVisible)

-- Change preview text when gui text changes
rx.Observable.from(textInput.FocusLost)
	:map(function () return textInput.Text end)
	:distinctUntilChanged()
	:subscribe(setPreviewText)

-- Place the preview when we're holding a stack
holdingStream
	:filter()
	:map(function (stack)
		return packageRaycastData(inputUtil.raycastMouse()), stack
	end)
	:filter(dart.boolAnd)
	:filter(function () return preview end)
	:subscribe(placePreview)

-- Bind click
pickupUtil.getClickWhileHoldingStream(stickyNoteStack)
	:map(function ()
		return packageRaycastData(inputUtil.raycastMouse()), getGuiText()
	end)
	:filter()
	:subscribe(dart.forward(stickyNoteStack.net.PlacementRequested))
	