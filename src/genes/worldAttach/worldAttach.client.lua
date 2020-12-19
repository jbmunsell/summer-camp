--
--	Jackson Munsell
--	18 Dec 2020
--	worldAttach.client.lua
--
--	worldAttach gene client driver
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local inputUtil = require(env.src.input.util)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)
local worldAttachUtil = require(genes.worldAttach.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local preview = nil
local rotation = 0

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function createPreview(instance)
	if preview then
		preview:Destroy()
		preview = nil
	end
	if instance then
		local rotationRange = instance.config.worldAttach.rotationRange.Value
		if rotationRange ~= 0 then
			rotation = math.rad((math.random() - 0.5) * rotationRange)
		else
			rotation = 0
		end
		preview = worldAttachUtil.createCopy(instance)
		instance.interface.worldAttach.PreviewCreated:Fire(preview)
	end
end

local function raycastMouse()
	return inputUtil.raycastMouse()
end

local function packageRaycastData()
	local result = raycastMouse()
	return result and {
		Instance = result.Instance,
		Position = result.Position,
		Normal = result.Normal,
		Material = result.Material,
	}
end

local function renderPreview(instance)
	if not preview then return end

	local result = raycastMouse()
	local hit = result and result.Position
	local show = false
	if instance and hit and result.Instance then
		show = worldAttachUtil.verifyRaycastResult(env.LocalPlayer, instance, result)

		if show then
			local stickAttachment = worldAttachUtil.getStickAttachment(preview)
			local offset = stickAttachment.WorldCFrame:toObjectSpace(axisUtil.getCFrame(preview))
			local hitCFrame = CFrame.new(hit, hit + result.Normal) * CFrame.Angles(0, 0, rotation)
			axisUtil.setCFrame(preview, hitCFrame:toWorldSpace(offset))
		end
	end
	preview.Parent = show and workspace or ReplicatedStorage
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.worldAttach)

-- When you are holding one, show preview
local holding = pickupUtil.getLocalCharacterHoldingStream(genes.worldAttach)
holding:subscribe(createPreview)
holding:switchMap(function (instance)
	return instance and rx.Observable.heartbeat():map(dart.constant(instance)) or rx.Observable.just()
end):subscribe(renderPreview)

-- Send to server on click
pickupUtil.getActivatedStream(genes.worldAttach)
	:map(packageRaycastData)
	:map(function (r) return r, rotation end)
	:filter()
	:filter(dart.index("Instance"))
	:subscribe(dart.forward(genes.worldAttach.net.AttachRequested))
