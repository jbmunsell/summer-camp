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
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)

-- lib
local plantInGroundUtil = {}

-- Try planting object in the ground
function plantInGroundUtil.tryPlant(instance)
	-- Strip from holder
	pickupUtil.stripObject(instance)

	-- Grab attachment
	local attachment = instance:FindFirstChild("PlantAttachment", true)
	if not attachment then error("No PlantAttachment found in " .. instance:GetFullName()) end

	-- Preserve Y rotation
	local alook = attachment.WorldCFrame.LookVector
	local rot = Vector3.new(alook.X, 0, alook.Z)

	-- Get terrain hit point
	local raycastResult = workspace:Raycast(attachment.WorldPosition, Vector3.new(0, -10, 0))
	if not raycastResult or raycastResult.Instance ~= workspace.Terrain then return end

	-- Create new terrain attachment for planting
	local terrainAttachment = Instance.new("Attachment", workspace.Terrain)
	terrainAttachment.CFrame = CFrame.new(raycastResult.Position, raycastResult.Position + rot)

	-- Smooth attach the things
	local weld = axisUtil.smoothAttachAttachments(workspace.Terrain, terrainAttachment, instance, "PlantAttachment")
	weld.Name = "StationaryWeld"
	weld.Parent = instance
	rx.Observable.fromInstanceLeftGame(weld)
		:first()
		:map(dart.constant(terrainAttachment))
		:subscribe(dart.destroy)

	-- Planted is TRUE
	if genesUtil.hasGeneTag(instance, genes.plantInGround) then
		instance.state.plantInGround.planted.Value = true
	end
end

-- return lib
return plantInGroundUtil
