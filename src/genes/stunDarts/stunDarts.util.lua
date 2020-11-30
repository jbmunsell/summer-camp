--
--	Jackson Munsell
--	24 Nov 2020
--	stunDarts.util.lua
--
--	stunDarts gene util
--

-- env
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local ragdoll = env.src.ragdoll

-- modules
local fx = require(axis.lib.fx)
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)
local activityUtil = require(genes.activity.util)

-- lib
local stunDartsUtil = {}

-- Process debounce and return valid to continue
function stunDartsUtil.processDebounce(instance)
	local stateValue = instance.state.stunDarts.debounce
	if stateValue.Value then return end
	stateValue.Value = true
	delay(instance.config.stunDarts.debounce.Value, function ()
		stateValue.Value = false
	end)
	return true
end

-- Get player from hit
local function getPlayerFromHit(hit)
	local player = axisUtil.getPlayerFromCharacterDescendant(hit)
	if player then return player end

	for _, p in pairs(genesUtil.getInstances(genes.player.characterBackpack):raw()) do
		local backpack = p.state.characterBackpack.instance.Value
		if backpack and hit:IsDescendantOf(backpack) then
			return p
		end
	end

	for _, v in pairs(genesUtil.getInstances(genes.pickup):raw()) do
		if (hit == v or hit:IsDescendantOf(v)) then
			local p = Players:GetPlayerFromCharacter(v.state.pickup.holder.Value)
			if p then
				return p
			end
		end
	end
end

-- Stun and affix
function stunDartsUtil.stunAndAffix(firingInstance, projectile, hit)
	-- First, affix
	local cleanup = rx.Observable.timer(3)
	local weld = Instance.new("Weld")
	weld.C0 = hit.CFrame:toObjectSpace(projectile.CFrame)
	weld.Part0 = hit
	weld.Part1 = projectile
	weld.Parent = projectile
	cleanup:map(dart.constant(projectile)):subscribe(dart.destroy)

	-- Check if player character AND they're in our roster
	local player = getPlayerFromHit(hit)
	print(player)
	local character = player and player.Character
	local activityInstance = firingInstance.state.pickup.activity.Value
	print(activityInstance)
	if not player or not character
	or player == firingInstance.state.pickup.owner.Value
	or not activityInstance or not activityUtil.isPlayerInRoster(activityInstance, player) then return end
	print("got player")

	-- Play crazy particles
	local emitter = firingInstance.config.stunDarts.characterParticles.Value:Clone()
	emitter.Parent = character.HumanoidRootPart
	emitter.Enabled = true
	delay(0.3, dart.bind(fx.smoothDestroy, emitter))

	-- Strip of non-stowable can-drop items
	local held = pickupUtil.getCharacterHeldObjects(character):first()
	if held then
		local pickupConfig = held.config.pickup
		if pickupConfig.canDrop.Value and not pickupConfig.stowable.Value then
			pickupUtil.unequipCharacter(character)
		end
	end

	-- Stun
	ragdoll.net.Push:FireClient(player)
	cleanup
		:filter(function () return player.Character == character end)
		:tap(print)
		:map(dart.constant(player))
		:subscribe(dart.forward(ragdoll.net.Pop))
end

-- fire dart
function stunDartsUtil.fireDart(character, firingInstance, origin, target)
	local sound = firingInstance.Handle:FindFirstChild("FireSound")
	if sound then
		sound:Play()
	end

	local config = firingInstance.config.stunDarts
	local projectile = config.projectile.Value:Clone()
	local unit = (target - origin).unit
	projectile.CFrame = CFrame.new(origin + unit * 2, target)
	projectile.Velocity = unit * config.shootMagnitude.Value
	projectile.Parent = workspace

	rx.Observable.fromInstanceEvent(projectile, "Touched")
		:first()
		:subscribe(function (hit)
			-- local params = RaycastParams.new()
			-- params.FilterType = Enum.RaycastFilterType.Whitelist
			-- params.FilterDescendantsInstances = { hit }
			-- local result = workspace:Raycast(projectile.Position, (hit.Position - projectile.Position), params)
			-- if not result then
			-- 	result = { Instance = hit, Position = (hit.Position + projectile.Position) * 0.5 }
			-- end
			stunDartsUtil.stunAndAffix(firingInstance, projectile, hit)
		end)

	-- local params = RaycastParams.new()
	-- params.FilterType = Enum.RaycastFilterType.Blacklist
	-- params.FilterDescendantsInstances = { character, firingInstance }
	-- rx.Observable.from(RunService.RenderStepped):map(function (dt)
	-- 	local jump = (projectile.Velocity + Vector3.new(0, workspace.Gravity * dt, 0)) * dt * 2
	-- 	return workspace:Raycast(projectile.Position, jump, params)
	-- end):filter(function (result)
	-- 	return result and result.Instance
	-- end):first():subscribe(dart.bind(stunDartsUtil.stunAndAffix, firingInstance, projectile))
end

-- return lib
return stunDartsUtil
