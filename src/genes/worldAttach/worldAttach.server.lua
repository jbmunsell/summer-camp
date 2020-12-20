--
--	Jackson Munsell
--	18 Dec 2020
--	worldAttach.server.lua
--
--	worldAttach gene server driver
--

-- env
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local fx = require(axis.lib.fx)
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local soundUtil = require(axis.lib.soundUtil)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)
local worldAttachUtil = require(genes.worldAttach.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function detachInstance(instance)
	axisUtil.destroyChildren(instance, "StickWeld")
	local function makeCollidable(part)
		if part:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(part, "Default")
		end
	end
	for _, d in pairs(instance:GetDescendants()) do
		makeCollidable(d)
	end
	makeCollidable(instance)
	fx.fadeOutAndDestroy(instance)
end

local function placeObject(player, instance, raycastResult, rotation)
	-- Place object
	local copy = worldAttachUtil.createCopy(instance)
	copy.Parent = workspace
	local instanceAttachment = worldAttachUtil.getStickAttachment(copy)
	local worldAttachment = Instance.new("Attachment", raycastResult.Instance)
	local hitCFrame = CFrame.new(raycastResult.Position, raycastResult.Position + raycastResult.Normal)
		* CFrame.Angles(0, 0, rotation)
	worldAttachment.CFrame = raycastResult.Instance.CFrame:toObjectSpace(hitCFrame)
	local weld = axisUtil.smoothAttachAttachments(raycastResult.Instance, worldAttachment,
		copy, instanceAttachment)
	weld.Name = "StickWeld"
	weld.Parent = copy
	rx.Observable.fromInstanceLeftGame(weld)
		:map(function () return worldAttachment:IsDescendantOf(game) and worldAttachment end)
		:filter()
		:first()
		:subscribe(dart.destroy)

	-- Detach and destroy stream
	local config = instance.config.worldAttach
	local isStuckToCharacter = false
	for _, p in pairs(Players:GetPlayers()) do
		if p.Character and raycastResult.Instance:IsDescendantOf(p.Character) then
			isStuckToCharacter = true
			break
		end
	end
	local dur = config[isStuckToCharacter and "characterAttachTimer" or "attachTimer"].Value
	local timer = (dur and rx.Observable.timer(dur) or rx.Observable.never())
	local playerLeft = (config.removeAfterOwnerLeft.Value
		and rx.Observable.from(Players.PlayerRemoving):filter(dart.equals(player))
		or rx.Observable.never())
	timer:merge(playerLeft)
		:first()
		:subscribe(dart.bind(detachInstance, copy))

	-- Play sound
	local sound = config.attachSound.Value
	if sound then
		soundUtil.playSound(sound, instanceAttachment)
	end

	-- Decrease count
	instance.state.worldAttach.count.Value = instance.state.worldAttach.count.Value - 1
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
genesUtil.initGene(genes.worldAttach):subscribe(function (instance)
	genesUtil.readConfigIntoState(instance, "worldAttach", "count")
end)

-- Destroy when count reaches zero
genesUtil.observeStateValue(genes.worldAttach, "count")
	:filter(function (_, count) return count <= 0 end)
	:subscribe(dart.destroy)

-- Handle placement requests
rx.Observable.from(genes.worldAttach.net.AttachRequested)
	:map(function (player, raycastResult, rotation)
		return player,
			pickupUtil.characterHoldsObject(player.Character, genes.worldAttach),
			raycastResult,
			rotation
	end)
	:filter(dart.boolAll)
	:filter(worldAttachUtil.verifyRaycastResult)
	:subscribe(placeObject)
