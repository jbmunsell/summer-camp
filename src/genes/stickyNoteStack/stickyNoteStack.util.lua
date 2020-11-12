--
--	Jackson Munsell
--	24 Oct 2020
--	stickyNoteStack.util.lua
--
--	Sticky note stack util
--

-- env
local CollectionService = game:GetService("CollectionService")
local TextService = game:GetService("TextService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)

-- lib
local stickyNoteStackUtil = {}

-- Get stick attachment
function stickyNoteStackUtil.getStickAttachment(instance)
	return instance:FindFirstChild("StickAttachment", true)
end

-- Filter player text
function stickyNoteStackUtil.filterPlayerText(player, text)
	local filteredMessage = "Text filtering error :/"
	local success, e = pcall(function ()
		local textObject = TextService:FilterStringAsync(text, player.UserId)
		filteredMessage = textObject:GetNonChatStringForBroadcastAsync()
	end)
	if not success then
		warn("Caught error:")
		warn(e)
	end
	return filteredMessage
end

-- Get attachment cframe
function stickyNoteStackUtil.getAttachmentCFrame(note, raycastData)
	return raycastData.instance.CFrame:toObjectSpace(stickyNoteStackUtil.getWorldCFrame(note, raycastData))
end

-- Get world cframe
function stickyNoteStackUtil.getWorldCFrame(note, raycastData)
	local config = note.config.stickyNoteStack
	return CFrame.new(raycastData.position, raycastData.position + raycastData.normal)
		* config.stickProtrusion.Value
		* config.stickAngle.Value
		* CFrame.Angles(0, 0, math.rad(raycastData.rotation or 0))
end

-- Render color
function stickyNoteStackUtil.renderColor(stack, color)
	if stack:IsA("BasePart") then
		stack.Color = color
		stack.SurfaceGui.Frame.BackgroundColor3 = color
	end
end

-- Stick a note according to raycast data
function stickyNoteStackUtil.stickNote(note, raycastData)
	-- Create attachment in target object and bind it to the lifetime of note
	local attachmentName = "StickAttachment" .. os.clock()
	local stickAttachment = Instance.new("Attachment", raycastData.instance)
	stickAttachment.Name = attachmentName
	stickAttachment.CFrame = stickyNoteStackUtil.getAttachmentCFrame(note, raycastData)
	stickyNoteStackUtil.getStickAttachment(note).Name = attachmentName

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
	tableau.from(note:GetDescendants())
		:filter(dart.isa("TextBox"))
		:foreach(function (box)
			box.Text = text
		end)
end

-- Tag note with FXPart so that it gets ignored by raycasts and stuff
function stickyNoteStackUtil.removeTags(note)
	for _, tag in pairs(CollectionService:GetTags(note)) do
		CollectionService:RemoveTag(note, tag)
	end
end
function stickyNoteStackUtil.tagNote(note)
	tableau.from(note:GetDescendants())
		:append({ note })
		:filter(dart.isa("BasePart"))
		:foreach(function (part)
			CollectionService:AddTag(part, "FXPart")
		end)
end

-- Create sticky note from raycast data and text
function stickyNoteStackUtil.createNote(stack, raycastData, text)
	local note = stack:Clone()
	stickyNoteStackUtil.removeTags(note)
	-- if note:IsA("Model") then
	-- 	note:SetPrimaryPartCFrame()
	-- else
	-- 	note.CFrame = stack.CFrame
	-- end
	stickyNoteStackUtil.tagNote(note)
	stickyNoteStackUtil.stickNote(note, raycastData)
	stickyNoteStackUtil.setNoteText(note, text)
	note.Parent = workspace
	return note
end

-- return lib
return stickyNoteStackUtil
