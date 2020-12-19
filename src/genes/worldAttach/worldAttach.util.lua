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
local axis = env.packages.axis

-- modules
local axisUtil = require(axis.lib.axisUtil)
local collection = require(axis.lib.collection)

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

-- Verify raycast result
function worldAttachUtil.verifyRaycastResult(player, instance, raycastResult)
	local p = axisUtil.getPlayerHumanoidRootPart(player).Position
	local d = (raycastResult.Position - p).magnitude
	local isInRange = d <= instance.config.worldAttach.attachRange.Value
	local config = instance.config.worldAttach
	local verified = false

	if isInRange and raycastResult.Instance then
		local tags = config.attachableTags:GetChildren()
		if #tags > 0 then
			for _, value in pairs(tags) do
				local tag = value.Value
				local tagged = axisUtil.getTaggedAncestor(raycastResult.Instance, tag, true)
				if tagged then
					verified = true
					break
				end
			end
		else
			verified = true
		end
	end

	if raycastResult.Instance == workspace.Terrain then
		local materials = config.attachableTerrainMaterials:GetChildren()
		if #materials > 0 then
			local materialString = string.match(tostring(raycastResult.Material), "([^%.]*)$")
			verified = collection.getValue(config.attachableTerrainMaterials, materialString)
		end
	end

	return verified
end

-- return lib
return worldAttachUtil
