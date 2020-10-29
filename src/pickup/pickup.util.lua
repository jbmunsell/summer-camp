--
--	Jackson Munsell
--	16 Oct 2020
--	pickupUtil.lua
--
--	Shared pickup util
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local pickup = env.src.pickup
local objects = env.src.objects

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local objectsUtil = require(objects.util)
local pickupConfig = require(pickup.config)
local inputStreams
if RunService:IsClient() then
	inputStreams = require(env.src.input.streams)
end

-- Non-lib functions
local function pushDropDebounce(object)
	object.state.pickup.dropDebounce.Value = true
	delay(pickupConfig.dropDebounce, function ()
		object.state.pickup.dropDebounce.Value = false
	end)
end
local function clearHolder(object)
	object.state.pickup.holder.Value = nil
end
local function clearOwner(object)
	object.state.pickup.owner.Value = nil
end
local function isStowable(object)
	return objectsUtil.getConfig(object).pickup.stowable
end
local function stowObject(object)
	object.Parent = ReplicatedStorage
end
local function getObjectRoot(object)
	return (object:IsA("BasePart") and object or object.PrimaryPart)
end
local function throwObjectAtTarget(object, target, power)
	local root = getObjectRoot(object)
	root.Velocity = (target - root.Position).unit * power
end
local function throwObjectInDirection(object, direction, power)
	getObjectRoot(object).Velocity = direction.unit * power
end

-- lib
local pickupUtil = {}

-- Check if a character holds an object
function pickupUtil.characterHoldsObject(character, class)
	if not character then return end
	return pickupUtil.getCharacterHeldObjects(character)
		:first(dart.hasTag(require(class.config).instanceTag))
end
function pickupUtil.localCharacterHoldsObject(class)
	return pickupUtil.characterHoldsObject(Players.LocalPlayer.Character, class)
end

-- Set equip override
function pickupUtil.setEquipOverride(object, equip)
	if not object.state.pickup:FindFirstChild("equipOverride") then
		Instance.new("BindableFunction", object.state.pickup).Name = "equipOverride"
	end
	object.state.pickup.equipOverride.OnInvoke = equip
end

-- Equip
-- 	Attaches an object to a character, smoothly if it's already in workspace
function pickupUtil.equip(character, object)
	-- If in workspace already, then smooth attach
	-- Otherwise, snap attach
	local isInWorkspace = object:IsDescendantOf(workspace)
	local attach = isInWorkspace
		and axisUtil.smoothAttach
		or axisUtil.snapAttach
	local weld = attach(character, object, "RightGripAttachment")
	weld.Name = "RightGripWeld"

	-- Place in workspace if not already
	-- 	This is for equipping stowed objects
	if not isInWorkspace then
		object.Parent = workspace
	end

	-- Set holder value
	object.state.pickup.holder.Value = character
	local player = dart.getPlayerFromCharacter(character)
	if player then
		object.state.pickup.owner.Value = player
	end
end

-- Get character held objects
function pickupUtil.getCharacterHeldObjects(character)
	return objectsUtil.getObjects(pickup)
		:filter(function (object)
			return object.state.pickup.holder.Value == character
		end)
end

-- Strip object
-- 	This function breaks an object's grip weld and clears its holder and owner state values
function pickupUtil.stripObject(object)
	if object.state.pickup.holder.Value then
		tableau.from(object.state.pickup.holder.Value:GetDescendants())
			:filter(function (instance)
				return instance.Name == "RightGripWeld"
				and (instance.Part1 == object or instance.Part1:IsDescendantOf(object))
			end)
			:foreach(dart.destroy)
	end
	clearOwner(object)
	clearHolder(object)
end

-- Unequip character
function pickupUtil.unequipCharacter(character)
	assert(character)

	-- Stow held objects that are stowable and clear owner for non-stowables
	pickupUtil.getCharacterHeldObjects(character)
		:foreach(function (object)
			if isStowable(object) then
				stowObject(object)
			else
				clearOwner(object)
				pushDropDebounce(object)
			end
		end)

	-- Drop objects (destroy welds)
	pickupUtil.releaseHeldObjects(character)
end

-- Drop character objects
function pickupUtil.releaseHeldObjects(character)
	-- Destroy grip welds
	tableau.from(character:GetDescendants())
		:filter(dart.isNamed("RightGripWeld"))
		:foreach(dart.destroy)

	-- Clear holder
	local root = character:FindFirstChild("HumanoidRootPart")
	local throwOffset = root and root.CFrame.lookVector or Vector3.new(0.01, 0.01, 0.01)
	pickupUtil.getCharacterHeldObjects(character)
		:foreach(function (object)
			clearHolder(object)
			if objectsUtil.getConfig(object).pickup.throwOnDrop then
				throwObjectInDirection(object, throwOffset)
			end
		end)
end

-- Update hold animation
function pickupUtil.updateHoldAnimation(character)
	local humanoid = character:FindFirstChild("Humanoid")
	local numHeld = pickupUtil.getCharacterHeldObjects(character):size()
	if numHeld > 0 then
		humanoid:LoadAnimation(env.res.pickup.ToolHoldAnimation):Play()
	else
		for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
			if track.Animation == env.res.pickup.ToolHoldAnimation then
				track:Stop()
			end
		end
	end
end

-- Disown object
function pickupUtil.disownHeldObjects(character)
	pickupUtil.getCharacterHeldObjects(character)
		:foreach(clearOwner)
end

-- Throw objects
function pickupUtil.throwCharacterObjects(character, target, power)
	-- Get held
	local held = pickupUtil.getCharacterHeldObjects(character)

	-- Break welds
	pickupUtil.disownHeldObjects(character)
	pickupUtil.releaseHeldObjects(character)

	-- Apply velocity
	held:foreach(function (object)
		throwObjectAtTarget(object, target, power)
	end)
end

-- Destroy player owned objects
-- 	This is called when a player leaves the game
function pickupUtil.destroyPlayerOwnedObjects(player)
	local function isOwned(instance)
		return instance.state.pickup.owner.Value == player
	end
	objectsUtil.getObjects(pickup)
		:filter(isOwned)
		:foreach(dart.destroy)
end

---------------------------------------------------------------------------------------------------
-- Stream factory functions
---------------------------------------------------------------------------------------------------

-- Get character holding stream
function pickupUtil.getLocalCharacterHoldingStream(class)
	assert(RunService:IsClient(), "pickupUtil.getCharacterHoldingStream can only be called from the client")

	-- Is local character holder
	local function isLocalCharacterHolder(instance)
		return env.LocalPlayer.Character
		and instance.state.pickup.holder.Value == env.LocalPlayer.Character
	end

	-- Any time an instance with this tag changes its holder, recompute the value and push
	return objectsUtil.getObjectsStream(class)
		:flatMap(function (instance)
			return rx.Observable.from(instance.state.pickup.holder)
				:merge(rx.Observable.fromInstanceLeftGame(instance))
		end)
		:map(function ()
			return objectsUtil.getObjects(class)
				:first(isLocalCharacterHolder)
		end)
		:map(dart.boolify)
		:distinctUntilChanged()
end

-- Get click while holding stream
function pickupUtil.getClickWhileHoldingStream(class)
	assert(RunService:IsClient(), "pickupUtil.getClickWhileHoldingStream can only be called from the client")

	return inputStreams.click
		:filter(function ()
			return pickupUtil.localCharacterHoldsObject(class)
		end)
end

-- Get player object action request stream
-- 	This takes a remote event and creates a stream properly filtered and
-- 	mapped to the player, held object of tag, and other parameters from the remote
function pickupUtil.getPlayerObjectActionRequestStream(remote, class)
	return rx.Observable.from(remote)
		:filter(dart.index("Character"))
		:map(function (player, ...)
			return player, pickupUtil.characterHoldsObject(player.Character, class), ...
		end)
		:filter(dart.boolAnd)
end

-- return lib
return pickupUtil
