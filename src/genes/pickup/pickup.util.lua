--
--	Jackson Munsell
--	16 Oct 2020
--	pickupUtil.lua
--
--	Shared pickup util
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local pickup = genes.pickup

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local characterUtil = require(env.src.character.util)
local inputStreams
if RunService:IsClient() then
	inputStreams = require(env.src.input.streams)
end

-- Non-lib functions
local function pushDropDebounce(object)
	object.state.pickup.dropDebounce.Value = true
	delay(object.config.pickup.dropDebounce.Value, function ()
		if object:IsDescendantOf(game) then
			object.state.pickup.dropDebounce.Value = false
		end
	end)
end
local function clearHolder(object)
	object.state.pickup.holder.Value = nil
end
local function clearOwner(object)
	object.state.pickup.owner.Value = nil
end
local function isStowable(object)
	return object.config.pickup.stowable.Value
end
local function stowObject(object)
	object.Parent = ReplicatedStorage
end

-- lib
local pickupUtil = {}

-- Check if a character holds an object
function pickupUtil.characterHoldsObject(character, gene)
	if not character then return end
	return pickupUtil.getCharacterHeldObjects(character)
		:first(dart.follow(genesUtil.hasGeneTag, gene))
end
function pickupUtil.localCharacterHoldsObject(gene)
	return pickupUtil.characterHoldsObject(Players.LocalPlayer.Character, gene)
end

-- Set equip override
function pickupUtil.setEquipOverride(object, equip)
	if not object.state.pickup:FindFirstChild("equipOverride") then
		Instance.new("BindableFunction", object.state.pickup).Name = "equipOverride"
	end
	object.state.pickup.equipOverride.OnInvoke = equip
end

-- Stow object for player
function pickupUtil.stowObjectForPlayer(player, object)
	object.state.pickup.owner.Value = player
	stowObject(object)
end

-- Equip
-- 	Attaches an object to a character, smoothly if it's already in workspace
function pickupUtil.equip(character, object)
	-- Destroy any stationary welds
	axisUtil.destroyChildren(object, "StationaryWeld")

	-- 	This is for equipping stowed objects
	local isInWorkspace = object:IsDescendantOf(workspace)
	if not isInWorkspace then
		axisUtil.setCFrame(object, character:GetPrimaryPartCFrame())
		-- object:SetPrimaryPartCFrame(character:GetPrimaryPartCFrame())
		object.Parent = workspace
	end

	-- Set holder value
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		object.state.pickup.owner.Value = player
	end
	object.state.pickup.holder.Value = character
end

-- Get character held objects
-- 	Init held object tracker
local _characterHeldObjects = {}
function pickupUtil.initHeldObjectTracking()
	genesUtil.getInstanceStream(pickup):flatMap(function (instance)
		return rx.Observable.from(instance.state.pickup.holder)
			:merge(rx.Observable.fromInstanceLeftGame(instance):map(dart.constant(nil)))
			:startWithArgs(nil)
			:replay(2)
			:map(function (a, b) return instance, a, b end)
	end)
	:subscribe(function (instance, oldHolder, newHolder)
		if _characterHeldObjects[oldHolder] then
			local t = _characterHeldObjects[oldHolder]:getValue()
			tableau.removeValue(t, instance)
			_characterHeldObjects[oldHolder]:push(t)
		end
		if _characterHeldObjects[newHolder] then
			local t = _characterHeldObjects[newHolder]:getValue()
			table.insert(t, instance)
			_characterHeldObjects[newHolder]:push(t)
		end
	end)
end
function pickupUtil.trackCharacterHeldObjects(character)
	_characterHeldObjects[character] = rx.BehaviorSubject.new({})
	rx.Observable.fromInstanceLeftGame(character):subscribe(function ()
		if _characterHeldObjects[character] then
			_characterHeldObjects[character]:destroy()
			_characterHeldObjects[character] = nil
		end
	end)
end
function pickupUtil.getCharacterHeldObjectsStream(character)
	while not _characterHeldObjects[character] do wait() end
	return _characterHeldObjects[character]
end
function pickupUtil.getCharacterHeldObjects(character)
	local sub = _characterHeldObjects[character]
	return sub and tableau.from(sub:getValue()) or tableau.empty()
	-- return genesUtil.getInstances(pickup)
	-- 	:filter(function (object)
	-- 		return object.state.pickup.holder.Value == character
	-- 	end)
end
function pickupUtil.getLocalCharacterHeldObjects()
	if not env.LocalPlayer.Character then return tableau.empty() end
	return pickupUtil.getCharacterHeldObjects(env.LocalPlayer.Character)
end

-- Strip object
-- 	This function breaks an object's grip weld and clears its holder and owner state values
function pickupUtil.stripObject(object)
	local holder = object.state.pickup.holder.Value
	if holder then
		axisUtil.destroyChildren(holder, "RightGrip")
	end
	-- object.Parent = workspace
	pushDropDebounce(object)
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
	axisUtil.destroyChildren(character, "RightGrip")

	-- Clear holder
	pickupUtil.getCharacterHeldObjects(character)
		:foreach(function (instance)
			clearHolder(instance) -- this should destroy grip welds
			-- if instance:IsDescendantOf(workspace) then
			-- 	instance.Parent = workspace
			-- end
		end)
end

-- Update hold animation
function pickupUtil.updateHoldAnimation(character)
	local humanoid = character:FindFirstChild("Humanoid")
	local held = pickupUtil.getCharacterHeldObjects(character):first()
	if held then
		local animation = held.config.pickup.holdAnimation.Value
		if animation then
			if not CollectionService:HasTag(animation, "holdAnimation") then
				CollectionService:AddTag(animation, "holdAnimation")
			end
			humanoid:LoadAnimation(animation):Play()
		end
	else
		for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
			if CollectionService:HasTag(track.Animation, "holdAnimation") then
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

-- Try drop held objects
function pickupUtil.tryDropHeldObjects(character)
	pickupUtil.getCharacterHeldObjects(character):foreach(function (object)
		if object.config.pickup.canDrop.Value then
			clearOwner(object)
		else
			stowObject(object)
		end
	end)
	pickupUtil.releaseHeldObjects(character)
end

-- Destroy player owned objects
-- 	This is called when a player leaves the game
function pickupUtil.destroyPlayerOwnedObjects(player)
	local function isOwned(instance)
		return instance.state.pickup.owner.Value == player
	end
	genesUtil.getInstances(pickup)
		:filter(isOwned)
		:foreach(dart.destroy)
end

---------------------------------------------------------------------------------------------------
-- Stream factory functions
---------------------------------------------------------------------------------------------------

-- Get character holding stream
function pickupUtil.getLocalCharacterHoldingStream(gene)
	assert(RunService:IsClient(), "pickupUtil.getCharacterHoldingStream can only be called from the client")

	return rx.Observable.from(env.LocalPlayer.CharacterAdded)
		:startWith(env.LocalPlayer.Character)
		:filter()
		:switchMap(function (character)
			return pickupUtil.getCharacterHeldObjectsStream(character)
				:map(dart.constant(character))
		end)
		:map(dart.follow(pickupUtil.characterHoldsObject, gene))
		:distinctUntilChanged()
end

-- Get click while holding stream
function pickupUtil.getClickWhileHoldingStream(gene)
	assert(RunService:IsClient(), "pickupUtil.getClickWhileHoldingStream can only be called from the client")

	return inputStreams.click
		:map(function (input)
			return pickupUtil.localCharacterHoldsObject(gene), input
		end)
		:filter()
end

-- Get player object action request stream
-- 	This takes a remote event and creates a stream properly filtered and
-- 	mapped to the player, held object of tag, and other parameters from the remote
function pickupUtil.getPlayerObjectActionRequestStream(remote, gene)
	return rx.Observable.from(remote)
		:filter(dart.index("Character"))
		:map(function (player, ...)
			return player, pickupUtil.characterHoldsObject(player.Character, gene), ...
		end)
		:filter(dart.boolAnd)
end

-- Get activated stream
function pickupUtil.getActivatedStream(gene)
	if RunService:IsClient() then
		return pickupUtil.getClickWhileHoldingStream(gene)
	elseif RunService:IsServer() then
		return rx.Observable.from(pickup.net.ObjectActivated)
			:map(function (player, ...)
				return player.Character, ...
			end)
			:filter()
			:map(function (character, _, ...) -- middle arg is the object they want to throw
				return character, pickupUtil.characterHoldsObject(character, gene), ...
			end)
			:filter(dart.boolAnd)
	end
end

-- Teleport player with held objects
function pickupUtil.teleportCharacterWithHeldObjects(character, cframe)
	local delta = character:GetPrimaryPartCFrame():toObjectSpace(cframe)
	for _, instance in pairs(pickupUtil.getCharacterHeldObjects(character):raw()) do
		if instance:IsA("BasePart") then
			instance.CFrame = instance.CFrame * delta
		elseif instance:IsA("Model") then
			instance:SetPrimaryPartCFrame(instance:GetPrimaryPartCFrame() * delta)
		end
	end
	characterUtil.teleportCharacter(character, cframe)
end

-- return lib
return pickupUtil
