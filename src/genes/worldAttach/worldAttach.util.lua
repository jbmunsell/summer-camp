--
--	Jackson Munsell
--	18 Dec 2020
--	worldAttach.util.lua
--
--	worldAttach gene util
--

-- env
local CollectionService = game:GetService("CollectionService")
local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules

-- lib
local worldAttachUtil = {}

-- Get stick attachment
function worldAttachUtil.getStickAttachment(instance)
	return instance:FindFirstChild("StickAttachment", true)
end

-- Create an intert copy
function worldAttachUtil.createCopy(instance)
	local copy = instance:Clone()
	for _, tag in pairs(CollectionService:GetTags(copy)) do
		CollectionService:RemoveTag(copy, tag)
	end
	local function tag(v)
		if v:IsA("BasePart") then
			CollectionService:AddTag(v, "FXPart")
		end
	end
	for _, d in pairs(copy:GetDescendants()) do
		tag(d)
	end
	tag(copy)
	return copy
end

-- return lib
return worldAttachUtil
