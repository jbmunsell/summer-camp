--
--	Jackson Munsell
--	11 Nov 2020
--	plantInGround.server.lua
--
--	plantInGround gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local plantInGround = genes.plantInGround
local pickup = genes.pickup

-- modules
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local pickupUtil = require(pickup.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local nextId = 0

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Create id
local function createId(instance)
	nextId = nextId + 1
	instance.state.plantInGround.plantId.Value = nextId
	local attachment = instance:FindFirstChild("PlantAttachment", true)
	if not attachment then error("No 'PlantAttachment' found in " .. instance:GetFullName()) end
	attachment.Name = attachment.Name .. instance.state.plantInGround.plantId.Value
end

-- Try planting object in the ground
local function tryPlant(instance)
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
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local plants = genesUtil.initGene(plantInGround)

-- Stick on activated or optional init
plants:filter(function (instance) return instance.config.plantInGround.initPlant.Value end)
	:merge(genesUtil.crossObserveStateValue(plantInGround, pickup, "holder")
		:reject(dart.select(2))
		:map(dart.select(1)))
	:subscribe(tryPlant)
