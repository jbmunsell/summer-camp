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
local genes = env.src.genes
local pickup = genes.pickup
local stickyNoteStack = genes.stickyNoteStack

-- modules
local rx = require(axis.lib.rx)
local fx = require(axis.lib.fx)
local dart = require(axis.lib.dart)
local soundUtil = require(axis.lib.soundUtil)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local pickupUtil = require(pickup.util)
local stickyNoteStackUtil = require(stickyNoteStack.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function setStackCount(stack)
	stack.state.stickyNoteStack.count.Value = stack.config.stickyNoteStack.count.Value
end

local function unstickNote(note)
	-- Destroy weld and place back into default collision group
	axisUtil.destroyChild(note, "StickWeld")
	tableau.from(note:GetDescendants())
		:append({ note })
		:filter(dart.isa("BasePart"))
		:foreach(function (p)
			PhysicsService:SetPartCollisionGroup(p, "Default")
		end)
	fx.fadeOutAndDestroy(note, note.config.stickyNoteStack.destroyAnimationDuration.Value)
end

-- Place stack note
local function placePlayerStackNote(player, stack, raycastData)
	-- Place sticky note object
	local note = stickyNoteStackUtil.createNote(stack, raycastData)

	-- Sticky note destroy stream
	local config = stack.config.stickyNoteStack
	local isStuckToCharacter = (raycastData.instance.Parent.Name == "PlayerBackpack")
	if not isStuckToCharacter then
		for _, p in pairs(Players:GetPlayers()) do
			if p.Character and raycastData.instance:IsDescendantOf(p.Character) then
				isStuckToCharacter = true
				break
			end
		end
	end
	local dur = config[isStuckToCharacter and "characterStickTimer" or "removeAfterTimer"].Value
	local timer = (dur and rx.Observable.timer(dur) or rx.Observable.never())
	local playerLeft = (config.removeAfterOwnerLeft.Value
		and rx.Observable.from(Players.PlayerRemoving):filter(dart.equals(player))
		or rx.Observable.never())
	timer:merge(playerLeft)
		:first()
		:subscribe(dart.bind(unstickNote, note))

	-- Decrease stack count
	stack.state.stickyNoteStack.count.Value = stack.state.stickyNoteStack.count.Value - 1
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Init all sticky note stacks
local stacks = genesUtil.initGene(stickyNoteStack)

-- Set stack count on init
stacks:subscribe(setStackCount)

-- Set text on thing
-- genesUtil.crossObserveStateValue(stickyNoteStack, genes.textConfigure, "text")
-- 	:subscribe(stickyNoteStackUtil.setNoteText)

-- Destroy stacks that are used up
genesUtil.observeStateValue(stickyNoteStack, "count")
	:map(dart.select(1))
	:filter(genesUtil.stateValueEquals(stickyNoteStack, "count", 0))
	:subscribe(dart.destroy)

-- Handle placement requests
local placementStream = pickupUtil.getPlayerObjectActionRequestStream(
	stickyNoteStack.net.PlacementRequested,
	stickyNoteStack
):filter(function (_, _, raycastData)
	return raycastData
	and raycastData.instance
	and raycastData.instance:IsDescendantOf(workspace)
end)
placementStream:subscribe(placePlayerStackNote)
placementStream:subscribe(function (_, instance)
	local attachment = instance:FindFirstChild("RightGripAttachment", true)
	if attachment then
		soundUtil.playRandom(env.res.genes.stickyNoteStack.sounds, attachment)
	end
end)

