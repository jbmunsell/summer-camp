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
local scheduleStreams = require(env.src.schedule.streams)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

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
	return tableau.from(workspace.ToyShop.config.itemColors:GetChildren()):random().Value
end

-- Special cases
local SpawnHandlers = {
	[objects.Balloon] = function (attachment, balloonInstance)
		axisUtil.snapAttachAttachments(attachment.Parent, attachment, balloonInstance, "StickAttachment")
	end,

	[objects.Ball] = function (_, ball)
		ball.Name = "GenericBall"
	end,
}

-- Place random item at attachment
local function placeRandomItemAtAttachment(attachment, itemList)
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
		genesUtil.getInstanceStream(genes.color)
			:filter(dart.equals(item))
			:map(getRandomColor)
			:map(dart.carry(item))
			:subscribe(genesUtil.setStateValue(genes.color, "color"))
	end
end

-- Destroy balls
local function destroyBalls()
	tableau.from(workspace.ToyShop:GetDescendants())
		:filter(dart.isNamed("GenericBall"))
		:foreach(dart.destroy)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Day start and end streams
local function fromTimeStream(t)
	return scheduleStreams.gameTime
		:map(function (time)
			return time > t
		end)
		:startWith(false)
		:distinctUntilChanged()
		:filter()
end
local dayStartStream = fromTimeStream(8)
local dayEndStream = fromTimeStream(18)

-- Spawn items on day start stream
local function spawnItemsAtAttachments(stream, instance, attachmentName, itemList)
	stream:flatMap(function ()
		return rx.Observable.from(instance:GetDescendants())
			:filter(dart.isa("Attachment"))
			:filter(dart.isNamed(attachmentName))
	end):map(dart.drag(itemList)):subscribe(placeRandomItemAtAttachment)
end
spawnItemsAtAttachments(dayStartStream, workspace.ToyShop, "BananaSpawn", { objects.BananaPeel })
spawnItemsAtAttachments(dayStartStream, workspace.ToyShop, "BallSpawn", { objects.Ball })
spawnItemsAtAttachments(dayStartStream, workspace.ToyShop, "BalloonSpawn", { objects.Balloon })
spawnItemsAtAttachments(dayStartStream, workspace.ToyShop, "ShelfItemSpawn", {
	objects.StickyNote,
	objects.A4,
	objects.WhoopieCushion,
	objects.PowderSack,
})

-- Destroy spawned balls at end of day
dayEndStream:subscribe(destroyBalls)
