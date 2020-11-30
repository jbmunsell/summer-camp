--
--	Jackson Munsell
--	29 Nov 2020
--	plantInGround.util.lua
--
--	plantInGround gene util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local axisUtil = require(axis.lib.axisUtil)
local pickupUtil = require(genes.pickup.util)

-- Variables
local nextId = 0

-- lib
local plantInGroundUtil = {}

-- Create id
local function createId(instance)
	nextId = nextId + 1
	instance.state.plantInGround.plantId.Value = nextId
	local attachment = instance:FindFirstChild("PlantAttachment", true)
	if not attachment then error("No 'PlantAttachment' found in " .. instance:GetFullName()) end
	attachment.Name = attachment.Name .. instance.state.plantInGround.plantId.Value
end

-- Try planting object in the ground
function plantInGroundUtil.tryPlant(instance)
	pickupUtil.stripObject(instance)

	-- Set value if not already
	local id = instance.state.plantInGround.plantId
	if id.Value < 0 then
		createId(instance)
	end

	-- Grab attachment
	local attachmentName = "PlantAttachment" .. id.Value
	local attachment = instance:FindFirstChild(attachmentName, true)
	if not attachment then error("No PlantAttachment found in " .. instance:GetFullName()) end

	-- Preserve Y rotation
	local alook = attachment.WorldCFrame.LookVector
	local rot = Vector3.new(alook.X, 0, alook.Z)

	-- Get terrain hit point
	local raycastResult = workspace:Raycast(attachment.WorldPosition, Vector3.new(0, -10, 0))
	if not raycastResult or raycastResult.Instance ~= workspace.Terrain then return end

	-- Create new terrain attachment for planting
	if not workspace.Terrain:FindFirstChild(attachmentName) then
		Instance.new("Attachment", workspace.Terrain).Name = attachmentName
	end
	local terrainAttachment = workspace.Terrain[attachmentName]
	terrainAttachment.CFrame = CFrame.new(raycastResult.Position, raycastResult.Position + rot)

	-- Smooth attach the things
	local weld = axisUtil.smoothAttach(workspace.Terrain, instance, attachmentName)
	weld.Name = "StationaryWeld"
	weld.Parent = instance

	-- Planted is TRUE
	instance.state.plantInGround.planted.Value = true
end

-- return lib
return plantInGroundUtil
