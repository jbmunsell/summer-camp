--
--	Jackson Munsell
--	12 Nov 2020
--	itemSpawning.server.lua
--
--	Item spawning server driver - spawns a bunch of items each morning and cleans
-- 	the old ones at the end of the day.
--

-- env
local CollectionService = game:GetService("CollectionService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local scheduleUtil = require(env.src.schedule.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local toyShop = workspace:FindFirstChild("ToyShop", true)
if not toyShop then
	warn("Toy shop not found; quitting")
	return
end

local objects = env.res.objects
local RandomizeColor = {
	[objects.StickyNote] = true,
	[objects.Balloon] = true,
	[objects.PowderSack] = true,
	[objects.Ball] = true,
}

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Get random color
local function getRandomColor()
	return tableau.from(toyShop.config.itemColors:GetChildren()):random().Value
end

-- Special cases
local SpawnHandlers = {
	[objects.Balloon] = function (attachment, balloonInstance)
		local weld = axisUtil.snapAttachAttachments(attachment.Parent, attachment, balloonInstance, "StickAttachment")
		weld.Name = "StationaryWeld"
		weld.Parent = balloonInstance
	end,

	[objects.Ball] = function (_, ball)
		ball.Name = "GenericBall"
	end,
}

-- Place random item at attachment
local function placeRandomItemAtAttachment(attachment, itemList)
	-- Track what has been spawned
	-- TEMPORARY until we create a real spawn gene
	if not attachment:FindFirstChild("spawnedInstance") then
		Instance.new("ObjectValue", attachment).Name = "spawnedInstance"
	end
	if attachment.spawnedInstance.Value then
		return
	end

	-- Clone item
	local itemSource = tableau.from(itemList):random()
	local item = itemSource:Clone()
	item.Parent = workspace
	axisUtil.setCFrame(item, attachment.WorldCFrame)
	local spawnAttachment = item:FindFirstChild("SpawnAttachment", true)
	if spawnAttachment then
		axisUtil.snapAttachments(attachment, spawnAttachment)
	end

	-- Special case spawning
	if SpawnHandlers[itemSource] then
		SpawnHandlers[itemSource](attachment, item)
	end

	-- Randomize color
	if RandomizeColor[itemSource] then
		genesUtil.waitForGene(item, genes.color)
		item.state.color.color.Value = getRandomColor()
	end

	-- Track spawned
	attachment.spawnedInstance.Value = item
	genesUtil.waitForGene(item, genes.pickup)
	rx.Observable.from(item.state.pickup.holder):filter():first():subscribe(function ()
		-- Clear attachment value so that we can spawn again
		attachment.spawnedInstance.Value = nil

		-- Set interact timer and add tracker tag so that we can destroy if nobody wants it
		genesUtil.waitForGene(item, genes.interact)
		item.state.interact.stamp.Value = os.time()
		CollectionService:AddTag(item, "SpawnedItem")
	end)
end

-- Cull spawned items
local function cullSpawnedItems()
	local timer = env.config.itemSpawning.StillnessDestroyTimer.Value
	for _, instance in pairs(CollectionService:GetTagged("SpawnedItem")) do
		if os.time() - instance.state.interact.stamp.Value >= timer then
			instance:Destroy()
		end
	end
end

-- Destroy balls
local function destroyBalls()
	tableau.from(toyShop:GetDescendants())
		:filter(dart.isNamed("GenericBall"))
		:foreach(dart.destroy)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Day start and end streams
local dayStartStream = scheduleUtil.getTimeOfDayStream(8)
local dayEndStream = scheduleUtil.getTimeOfDayStream(18)

-- Spawn items on day start stream
local function spawnItemsAtAttachments(stream, instance, attachmentName, itemList)
	stream:flatMap(function ()
		return rx.Observable.from(instance:GetDescendants())
			:filter(dart.isa("Attachment"))
			:filter(dart.isNamed(attachmentName))
	end):map(dart.drag(itemList)):subscribe(placeRandomItemAtAttachment)
end
spawnItemsAtAttachments(dayStartStream, toyShop, "BananaSpawn", { objects.BananaPeel })
spawnItemsAtAttachments(dayStartStream, toyShop, "BallSpawn", { objects.Ball })
spawnItemsAtAttachments(dayStartStream, toyShop, "BalloonSpawn", { objects.Balloon })
spawnItemsAtAttachments(dayStartStream, toyShop, "ShelfItemSpawn", {
	objects.StickyNote,
	objects.A4,
	objects.WhoopieCushion,
	objects.PowderSack,
})

-- Destroy spawned balls at end of day
dayEndStream:subscribe(destroyBalls)

-- Destroy spawned items if they haven't been interacted with in 5 minutes
rx.Observable.interval(10):subscribe(cullSpawnedItems)

---------------------------------------------------------------------------------------------------
-- Marshmallow spawning
---------------------------------------------------------------------------------------------------

local spawned = {}
scheduleUtil.getTimeOfDayStream(18):subscribe(function ()
	for _, child in pairs(env.res.sticksAndMarshmallows:GetChildren()) do
		local copy = child:Clone()
		copy.Parent = workspace
		table.insert(spawned, copy)

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = workspace.Terrain
		weld.Part1 = (copy:IsA("Model") and copy.PrimaryPart or copy)
		weld.Name = "StationaryWeld"
		weld.Parent = copy

		if #spawned % 5 == 0 then
			wait()
		end
	end
end)
scheduleUtil.getTimeOfDayStream(22):subscribe(function ()
	for _, item in pairs(spawned) do
		item:Destroy()

		if #spawned % 3 == 0 then
			wait()
		end
	end
	spawned = {}
end)

---------------------------------------------------------------------------------------------------
-- Winter item spawning
---------------------------------------------------------------------------------------------------

local winterSpawned = {}
scheduleUtil.getTimeOfDayStream(8.2):merge(scheduleUtil.getTimeOfDayStream(14)):subscribe(function ()
	for _, child in pairs(env.res.winterItems:GetChildren()) do
		local copy = child:Clone()
		copy.Parent = workspace
		table.insert(winterSpawned, copy)

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = workspace.Terrain
		weld.Part1 = (copy:IsA("Model") and copy.PrimaryPart or copy)
		weld.Name = "StationaryWeld"
		weld.Parent = copy

		if #winterSpawned % 5 == 0 then
			wait()
		end
	end
end)
scheduleUtil.getTimeOfDayStream(21.8):subscribe(function ()
	for _, item in pairs(winterSpawned) do
		item:Destroy()

		if #winterSpawned % 3 == 0 then
			wait()
		end
	end
	winterSpawned = {}
end)

---------------------------------------------------------------------------------------------------
-- Tip generation
---------------------------------------------------------------------------------------------------

local tipLabel = workspace:FindFirstChild("HowToPlay", true):FindFirstChild("TipTextLabel", true)
local tips = tableau.from(env.res.tips:GetChildren())
local function shuffleTip()
	local tip = tips:random()
	tipLabel.Text = tip.Value
end
rx.Observable.interval(20):subscribe(shuffleTip)
