--
--	Jackson Munsell
--	16 Oct 2020
--	pickup.server.lua
--
--	Pickup server driver. Initializes pickup state and drives pickup functionality
-- 	for tagged genes.
--

-- env
local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")
local CollectionService = game:GetService("CollectionService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local pickup = genes.pickup
local interact = genes.interact
local multiswitch = genes.multiswitch

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local pickupUtil = require(pickup.util)
local genesUtil = require(genes.util)
local multiswitchUtil = require(multiswitch.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Fire drop event
local function fireDropEvent(character)
	local instance = pickupUtil.getCharacterHeldObjects(character):first()
	local player = Players:GetPlayerFromCharacter(character)
	if not player or not instance then return end
	AnalyticsService:FireEvent("objectDropped", {
		instanceName = instance.Name,
		instanceTags = CollectionService:GetTags(instance),
		playerId = player.UserId,
	})
end

-- Fire activated event
local function fireActivatedEvent(character, instance)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end
	AnalyticsService:FireEvent("objectActivated", {
		instanceName = instance.Name,
		instanceTags = CollectionService:GetTags(instance),
		playerId = player.UserId,
	})
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Pickup object stream
local pickupInstanceStream = genesUtil.initGene(pickup)

-- Activated event
-- pickupUtil.getActivatedStream(pickup):tap(print):subscribe(fireActivatedEvent)

-- Track all character held objects
pickupUtil.initHeldObjectTracking()
axisUtil.getPlayerCharacterStream()
	:map(dart.select(2))
	:subscribe(function (character)
		pickupUtil.trackCharacterHeldObjects(character)
		pickupUtil.getCharacterHeldObjectsStream(character)
			:map(dart.constant(character))
			:subscribe(pickupUtil.updateHoldAnimation)
	end)

-- We should only be able to interact with an object if it has no holder and is enabled
pickupInstanceStream
	:flatMap(function (instance)
		local interactEnabled = instance.config.pickup.interactPickupEnabled.Value
		return rx.Observable.from(instance.state.pickup.holder)
			:map(dart.boolNot)
			:combineLatest(rx.Observable.from(instance.state.pickup.enabled),
				rx.Observable.just(interactEnabled),
				dart.boolAll)
			:map(dart.carry(instance, "interact", "pickup"))
	end)
	:subscribe(multiswitchUtil.setSwitchEnabled)

-- Connect to pickup objects that have touch enabled
local touchPickupStream = pickupInstanceStream
	:filter(function (instance)
		return instance.config.pickup.touchPickupEnabled.Value
	end)
	:flatMap(rx.Observable.fromPlayerTouchedDescendant)
	:map(function (instance, player)
		return player, instance
	end)

-- Server equip and unequip streams
-- 	NOT implemented yet so we swap with Observable.never()
local serverEquipPlayerStream = rx.Observable.never()
local serverUnequipPlayerStream = rx.Observable.never()

-- Client pickup stream
-- 	When a client interacts with a pickup object
local clientPickupRequestStream = rx.Observable.from(interact.net.ClientInteracted)
local toggleEquipRequestStream = rx.Observable.from(pickup.net.ToggleEquipRequested)
	:filter(function (client, object)
		return object.state.pickup.owner.Value == client
	end)
local unequipRequestStream, equipFromInventoryRequestStream = toggleEquipRequestStream
	:map(function (player, object)
		return player, object, object:IsDescendantOf(workspace)
	end)
	:share() -- This crazy business is needed because a multi-subscription observable
				-- is modified by one of its downstream subscribers in such a way that
				-- the result of the evaluation function will change. By reparenting
				-- the object, object:IsDescendantOf(workspace) changes, so it will
				-- affect the result of whichever subscriber is called second
	:partition(function (_, _, equipped)
		return equipped
	end)

-- Equip stream
-- 	Composed of client E pickups, client equips from backpack, and server equips
-- 	of any kind.
local playerEquipStream = clientPickupRequestStream
	:merge(equipFromInventoryRequestStream, serverEquipPlayerStream, touchPickupStream)
local characterEquipStream = playerEquipStream
	:map(function (player, instance)
		return player.Character, instance
	end)
	:filter(function (character, instance)
		return genesUtil.hasGeneTag(instance, pickup)
		and character and not instance.state.pickup.holder.Value
		and instance.state.pickup.enabled.Value
		and not instance.state.pickup.dropDebounce.Value
	end)
characterEquipStream:subscribe(function (character, instance)
	if instance.state.pickup:FindFirstChild("equipOverride") then
		instance.state.pickup.equipOverride:Invoke(character, instance)
	else
		pickupUtil.unequipCharacter(character)
		pickupUtil.equip(character, instance)
	end
	-- pickup.net.ObjectEquipped:FireAllClients(character, instance)
end)

-- Unequip stream
-- 	Composed of client unequip request from backpack, server unequips,
-- 	and a different item is equipped. Unequip will stow in inventory if
-- 	stowable, OR drop back into workspace if not stowable.
local unequipStream = unequipRequestStream
	-- :merge(serverUnequipPlayerStream, playerEquipStream)
	:merge(serverUnequipPlayerStream)
	:map(dart.index("Character"))
	:filter()
unequipStream:subscribe(pickupUtil.unequipCharacter)

-- Drop stream
-- 	Composed of humanoid died events. Drops an item back
-- 	into the world instead of stowing in inventory.
local characterDiedStream = axisUtil.getHumanoidDiedStream()
	:map(dart.index("Parent"))
	:filter()
characterDiedStream:subscribe(pickupUtil.releaseHeldObjects)

-- Disown and drop items on request
local dropStream = rx.Observable.from(pickup.net.DropRequested)
	:map(dart.index("Character"))
	:filter()
dropStream:subscribe(function (character)
	fireDropEvent(character)
	pickupUtil.disownHeldObjects(character)
	pickupUtil.releaseHeldObjects(character)
end)

-- Destroy all of a player's stowed items when they leave the server
-- TODO: Some sort of save data hook here
rx.Observable.from(Players.PlayerRemoving)
	:subscribe(function (player)
		if player.Character then
			pickupUtil.unequipCharacter(player.Character)
		end
		-- TODO: Serialize and save
		pickupUtil.destroyPlayerOwnedObjects(player)
	end)
