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

local function attachToCharacter(character, instance)
	axisUtil.setCFrame(instance, character:GetPrimaryPartCFrame())
	instance.Parent = workspace
	for _, d in pairs(instance:GetDescendants()) do
		if d:IsA("Attachment") then
			local characterAttachment = character:FindFirstChild(d.Name, true)
			if characterAttachment then
				axisUtil.snapAttachAttachments(character, characterAttachment, instance, d)
				break
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Pickup object stream
local pickupInstanceStream = genesUtil.initGene(pickup)

-- Attach extras on equip
genesUtil.observeStateValue(pickup, "holder"):filter(dart.select(2))
	:subscribe(function (instance, holder)
		local extras = {}
		for _, entry in pairs(instance.config.pickup.extras:GetChildren()) do
			if entry.Value then
				local e = entry.Value:Clone()
				table.insert(extras, e)
				attachToCharacter(holder, e)
				if genesUtil.hasGeneTag(instance, genes.teamLink) then
					genesUtil.addGeneAsync(e, genes.teamLink)
					rx.Observable.from(instance.state.teamLink.team)
						:takeUntil(rx.Observable.fromInstanceLeftGame(e))
						:subscribe(function (team)
							e.state.teamLink.team.Value = team
						end)
				end
			end
		end
		rx.Observable.from(instance.state.pickup.holder):reject():first():subscribe(function ()
			for _, e in pairs(extras) do
				e:Destroy()
			end
		end)
	end)

-- Track all character held objects
pickupUtil.initHeldObjectTracking()
axisUtil.getPlayerCharacterStream():map(dart.select(2)):subscribe(function (character)
	pickupUtil.trackCharacterHeldObjects(character)
	pickupUtil.getCharacterHeldObjectsStream(character)
		:merge(rx.Observable.fromInstanceEvent(character:WaitForChild("Humanoid"), "StateChanged")
			:filter(dart.equals(Enum.HumanoidStateType.Physics)))
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
	:reject(function (player)
		return player.Character.Humanoid:GetState() == Enum.HumanoidStateType.Physics
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
		and character:FindFirstChild("Humanoid")
		and character.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead
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
local playerCharacterDiedStream = axisUtil.getPlayerCharacterStream()
	:flatMap(function (player, character)
		return rx.Observable.fromInstanceEvent(character:WaitForChild("Humanoid"), "Died")
			:map(dart.constant(player))
	end)
local unequipStream = unequipRequestStream
	-- :merge(serverUnequipPlayerStream, playerEquipStream)
	:merge(serverUnequipPlayerStream, playerCharacterDiedStream)
	:map(dart.index("Character"))
	:filter()
unequipStream:subscribe(pickupUtil.unequipCharacter)

-- Disown and drop items on request
local dropStream = rx.Observable.from(pickup.net.DropRequested)
	:map(dart.index("Character"))
	:filter()
dropStream:subscribe(pickupUtil.tryDropHeldObjects)

-- Set an object's network owner according to who OWNS it
genesUtil.observeStateValue(pickup, "holder"):subscribe(function (instance, holder)
	if not instance:IsDescendantOf(workspace) or instance:FindFirstChild("StationaryWeld", true) then return end
	local root = instance
	if instance:IsA("Model") then
		root = instance.PrimaryPart
		if not root then
			error(instance:GetFullName() .. " does not have a PrimaryPart")
		end
	end
	root = root:GetRootPart() or root

	local player = holder and Players:GetPlayerFromCharacter(holder)
	root:SetNetworkOwner(player)

	if holder then
		local weld = axisUtil.smoothAttach(holder, instance, "RightGripAttachment")
		weld.Name = "RightGrip"
		weld.Parent = holder
		-- local rightGrip = instance:FindFirstChild("RightGripAttachment", true)
		-- local weld = Instance.new("Weld")
		-- weld.Part0 = holder:FindFirstChild("RightHand")
		-- weld.Part1 = rightGrip.Parent
		-- weld.C0 = weld.Part0.CFrame:toObjectSpace(weld.Part1.CFrame)
		-- weld.Name = "RightGrip"
		-- weld.Parent = holder
		-- if not player then
		-- 	weld.C0 = holder:FindFirstChild("RightGripAttachment", true).CFrame * rightGrip.CFrame
		-- else
		-- 	print("player grabbed; allowing them to set grip")
		-- end
	end
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
