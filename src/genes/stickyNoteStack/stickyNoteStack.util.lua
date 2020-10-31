--
--	Jackson Munsell
--	24 Oct 2020
--	stickyNoteStack.util.lua
--
--	Sticky note stack util
--

-- env
local CollectionService = game:GetService("CollectionService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)

-- lib
local stickyNoteStackUtil = {}

-- Filter player text
function stickyNoteStackUtil.filterPlayerText(player, text)
	local filteredMessage = "Text filtering error :/"
	pcall(function ()
		local textObject = env.TextService:FilterStringAsync(text, player.UserId)
		filteredMessage = textObject:GetNonChatStringForBroadcastAsync()
	end)
	return filteredMessage
end

-- Get attachment cframe
function stickyNoteStackUtil.getAttachmentCFrame(note, raycastData)
	return raycastData.instance.CFrame:toObjectSpace(stickyNoteStackUtil.getWorldCFrame(note, raycastData))
end

-- Get world cframe
function stickyNoteStackUtil.getWorldCFrame(note, raycastData)
	local config = genesUtil.getConfig(note).stickyNoteStack
	return CFrame.new(raycastData.position, raycastData.position + raycastData.normal)
		* config.stickProtrusion
		* config.stickAngle
		* CFrame.Angles(0, 0, math.rad(raycastData.rotation or 0))
end

-- Stick a note according to raycast data
function stickyNoteStackUtil.stickNote(note, raycastData)
	-- Create attachment in target object and bind it to the lifetime of note
	local attachmentName = "StickAttachment" .. os.clock()
	local stickAttachment = Instance.new("Attachment", raycastData.instance)
	stickAttachment.Name = attachmentName
	stickAttachment.CFrame = stickyNoteStackUtil.getAttachmentCFrame(note, raycastData)
	note.StickAttachment.Name = attachmentName

	-- Smoothly weld the bitches together
	local weld = axisUtil.smoothAttach(raycastData.instance, note, attachmentName)
	weld.Name = "StickWeld"
	weld.Parent = note
	rx.Observable.fromInstanceLeftGame(weld)
		:map(function ()
			return stickAttachment:IsDescendantOf(game) and stickAttachment
		end)
		:subscribe(dart.destroy)
end

-- Set note text
function stickyNoteStackUtil.setNoteText(note, text)
	local textbox = note:FindFirstChildWhichIsA("TextBox", true)
	if textbox then
		textbox.Text = text
	else
		warn("Could not find TextBox as descendant of StickyNote")
	end
end

-- Tag note with FXPart so that it gets ignored by raycasts and stuff
function stickyNoteStackUtil.tagNote(note)
	CollectionService:AddTag(note, "FXPart")
end

-- Create sticky note from raycast data and text
function stickyNoteStackUtil.createNote(stack, raycastData, text)
	local note = env.res.genes.StickyNote:Clone()
	note.Color = stack.Color
	note.CFrame = stack.CFrame
	stickyNoteStackUtil.tagNote(note)
	stickyNoteStackUtil.stickNote(note, raycastData)
	stickyNoteStackUtil.setNoteText(note, text)
	note.Parent = workspace
	return note
end

-- return lib
return stickyNoteStackUtil
