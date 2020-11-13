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
	assert(attachment, "No 'PlantAttachment' found in " .. instance:GetFullName())
	attachment.Name = attachment.Name .. instance.state.plantInGround.plantId.Value
end

-- unplant
local function unplant(instance)
	axisUtil.destroyChild(instance, "PlantWeld")
end

-- Try planting object in the ground
local function tryPlant(instance)
	pickupUtil.stripObject(instance)

	-- Grab attachment
	local attachmentName = "PlantAttachment" .. instance.state.plantInGround.plantId.Value
	local attachment = instance:FindFirstChild(attachmentName, true)
	assert(attachment, "No PlantAttachment found in " .. instance:GetFullName())

	-- Get terrain hit point
	local raycastResult = workspace:Raycast(attachment.WorldPosition, Vector3.new(0, -10, 0))
	if not raycastResult or raycastResult.Instance ~= workspace.Terrain then return end

	-- Create new terrain attachment for planting
	if not workspace.Terrain:FindFirstChild(attachmentName) then
		Instance.new("Attachment", workspace.Terrain).Name = attachmentName
	end
	workspace.Terrain:FindFirstChild(attachmentName).CFrame = CFrame.new(raycastResult.Position)

	-- Smooth attach the things
	local weld = axisUtil.smoothAttach(workspace.Terrain, instance, attachmentName)
	weld.Name = "PlantWeld"
	weld.Parent = instance
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local plants = genesUtil.initGene(plantInGround)

-- Create plant ids
plants:subscribe(createId)

-- Stick on activated or optional init
plants:filter(function (instance) return instance.config.plantInGround.initPlant.Value end)
	:merge(pickupUtil.getActivatedStream(plantInGround)
		:map(dart.select(2)))
	:subscribe(tryPlant)

-- On pickup, destroy plant weld
genesUtil.crossObserveStateValue(plantInGround, pickup, "holder")
	:filter(dart.select(2))
	:map(dart.select(1))
	:subscribe(unplant)
