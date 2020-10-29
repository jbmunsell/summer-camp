--
--	Jackson Munsell
--	22 Oct 2020
--	stickyNoteStack.server.lua
--
--	Sticky note stack server driver - handles sticky note placement
--

-- env
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local pickup = env.src.pickup
local objects = env.src.objects
local stickyNoteStack = env.src.objects.stickyNoteStack

-- modules
local rx = require(axis.lib.rx)
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local objectsUtil = require(objects.util)
local pickupUtil = require(pickup.util)
local stickyNoteStackUtil = require(stickyNoteStack.util)
local stickyNoteStackConfig = require(stickyNoteStack.config)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function unstickNote(note)
	-- Destroy weld and place back into default collision group
	axisUtil.destroyChild(note, "StickWeld")
	PhysicsService:SetPartCollisionGroup(note, "Default")
	fx.fadeOutAndDestroy(note, stickyNoteStackConfig.destroyAnimationDuration)
end

-- Place stack note
local function placePlayerStackNote(player, stack, raycastData, text)
	-- Decrease stack count
	stack.state.stickyNoteStack.count.Value = stack.state.stickyNoteStack.count.Value - 1
	if stack.state.stickyNoteStack.count.Value <= 0 then
		stack:Destroy()
	end

	-- Place sticky note object
	local filteredText = stickyNoteStackUtil.filterPlayerText(player, text)
	local note = stickyNoteStackUtil.createNote(stack, raycastData, filteredText)

	-- Sticky note destroy stream
	local dur = stickyNoteStackConfig.removeAfterTimer
	local timer = (dur and rx.Observable.timer(dur) or rx.Observable.never())
	local playerLeft = (stickyNoteStackConfig.removeAfterOwnerLeft
		and rx.Observable.from(Players.PlayerRemoving):filter(dart.equals(player))
		or rx.Observable.never())
	timer:merge(playerLeft)
		:first()
		:subscribe(dart.bind(unstickNote, note))
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Init all sticky note stacks
objectsUtil.initObjectClass(stickyNoteStack)

-- Handle placement requests
pickupUtil.getPlayerObjectActionRequestStream(
	stickyNoteStack.net.PlacementRequested,
	stickyNoteStack
)	:filter(function (_, _, raycastData)
		return raycastData
		and raycastData.instance
		and raycastData.instance:IsDescendantOf(workspace)
	end)
	:subscribe(placePlayerStackNote)

