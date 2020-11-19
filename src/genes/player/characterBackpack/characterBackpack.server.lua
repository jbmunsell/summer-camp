--
--	Jackson Munsell
--	13 Nov 2020
--	characterBackpack.server.lua
--
--	characterBackpack gene server driver
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local characterBackpack = genes.player.characterBackpack

-- modules
local fx = require(axis.lib.fx)
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local playerUtil = require(genes.player.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Set backpack color
local function setBackpackTeam(instance, team, isLeader)
	local config = team.config.team
	local color = (isLeader and Color3.new(0.3, 0.3, 0.3) or config.color.Value)
	local image = config.image.Value
	instance.Handle.SpecialMesh.VertexColor = Vector3.new(color.R, color.G, color.B)
	instance.DecalPart.Color = color
	instance.DecalPart.Decal.Texture = image
end

-- Set backpack scale
local function setBackpackScale(instance, scale)
	instance.ScaleEffect.Value = scale
end

-- Set backpack enabled
local function setBackpackEnabled(instance, enabled, character)
	axisUtil.destroyChild(instance, "AttachWeld")
	instance.Parent = (enabled and workspace or ReplicatedStorage)
	if enabled then
		wait()
		local weld = axisUtil.snapAttach(character, instance, "BodyBackAttachment")
		weld.Name = "AttachWeld"
		weld.Parent = instance
	end
end

-- Create backpack
local function createBackpack(player)
	-- Create backpack instance
	local backpack = env.res.roles.PlayerBackpack:Clone()
	fx.new("ScaleEffect", backpack)
	player.state.characterBackpack.instance.Value = backpack

	-- Parent to workspace when there's a character and NOT in a competitive activity,
	-- 	and ReplicatedStorage otherwise
	-- local competingStream = activityUtil.getPlayerCompetingStream(player)
	local competingStream = rx.Observable.just(false)
	local enabledStream = rx.Observable.fromInstanceEvent(player, "CharacterAdded")
		:startWith(player.Character)
		:combineLatest(competingStream, function (character, competing)
			return (character and not competing), character
		end)
	enabledStream:subscribe(dart.bind(setBackpackEnabled, backpack))

	-- Set color according to team
	local isLeader = rx.Observable.from(player.state.leader.isLeader)
	rx.Observable.fromProperty(player, "Team", true)
		:combineLatest(isLeader, dart.identity)
		:subscribe(dart.bind(setBackpackTeam, backpack))

	-- Set size according to leader
	isLeader
		:map(function (v)
			local pre = (v and "leader" or "camper")
			return env.config.roles[pre .. "BackpackScale"].Value
		end)
		:withLatestFrom(enabledStream)
		:subscribe(function (scale, enabled)
			setBackpackScale(backpack, scale)
			setBackpackEnabled(backpack, enabled, player.Character)
		end)
end

-- Destroy player backpack
local function destroyPlayerBackpack(player)
	local instance = player.state.characterBackpack.instance.Value
	if instance then
		instance:Destroy()
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local playerStream = playerUtil.softInitPlayerGene(characterBackpack)

-- Create instance for each gene
playerStream:subscribe(createBackpack)

-- Destroy backpacks on player left
rx.Observable.from(Players.PlayerRemoving)
	:filter(dart.follow(genesUtil.hasFullState, characterBackpack))
	:subscribe(destroyPlayerBackpack)
