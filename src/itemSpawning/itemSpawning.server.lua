--
--	Jackson Munsell
--	12 Nov 2020
--	itemSpawning.server.lua
--
--	Item spawning server driver - spawns a bunch of items each morning and cleans
-- 	the old ones at the end of the day.
--

-- env
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
		weld.Parent = balloonInstance
		weld.Name = "StationaryWeld"
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
		print("Attachment still has object; returning")
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
		genesUtil.waitForState(item, genes.color)
		item.state.color.color.Value = getRandomColor()
	end

	-- Track spawned
	attachment.spawnedInstance.Value = item
	genesUtil.waitForState(item, genes.pickup)
	rx.Observable.from(item.state.pickup.holder):filter():first():subscribe(function ()
		print("Item grabbed; clearing attachment")
		attachment.spawnedInstance.Value = nil
	end)
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

---------------------------------------------------------------------------------------------------
-- Marshmallow spawning
---------------------------------------------------------------------------------------------------

scheduleUtil.getTimeOfDayStream(18):subscribe(function ()
	local folder = env.res.sticksAndMarshmallows:Clone()
	folder.Parent = workspace
	for _, d in pairs(folder:GetChildren()) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = workspace.Terrain
		weld.Part1 = d
		weld.Name = "StationaryWeld"
		weld.Parent = d
	end
end)
scheduleUtil.getTimeOfDayStream(22):subscribe(dart.bind(axisUtil.destroyChild, workspace, "sticksAndMarshmallows"))

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
