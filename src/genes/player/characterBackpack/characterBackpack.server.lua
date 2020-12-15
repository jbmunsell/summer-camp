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

-- Set backpack enabled
local function attachBackpackToCharacter(instance, character)
	axisUtil.destroyChild(instance, "AttachWeld")
	instance.Parent = workspace
	wait()
	local weld = axisUtil.snapAttach(character, instance, "BodyBackAttachment")
	weld.Name = "AttachWeld"
	weld.Parent = instance
end

-- Create backpack
local function createBackpack(player)
	-- Create backpack instance
	genesUtil.waitForGene(player, genes.player.jobs)
	local backpack = env.res.character.PlayerBackpack:Clone()
	backpack.Parent = ReplicatedStorage
	genesUtil.waitForGene(backpack, genes.color)
	fx.new("ScaleEffect", backpack)
	player.state.characterBackpack.instance.Value = backpack

	-- Terminator stream
	-- NOTE: We cannot use the delay operator because the stream completes
	-- 	since it's technically a :first(), so delay observer push will be debounced
	local terminator = rx.Observable.fromInstanceLeftGame(backpack)
	terminator
		:reject(function () return player.state.characterBackpack.destroyed.Value end)
		:subscribe(function ()
			delay(0.1, dart.bind(createBackpack, player))
		end)

	-- Attach to new characters while backpack exists
	rx.Observable.fromInstanceEvent(player, "CharacterAdded")
		:startWith(player.Character)
		:filter(function (c)
			return c and c:FindFirstChild("Humanoid")
			and c.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead
		end)
		:takeUntil(terminator)
		:subscribe(dart.bind(attachBackpackToCharacter, backpack))

	-- Set color according to team
	local isLeaderStream = rx.Observable.from(player.state.jobs.job):map(dart.equals(env.res.jobs.teamLeader))
	rx.Observable.fromProperty(player, "Team", true)
		:takeUntil(terminator)
		:subscribe(function (team)
			backpack.state.teamLink.team.Value = team
		end)
	rx.Observable.from(backpack.state.teamLink.team)
		:filter(dart.follow(genesUtil.hasGeneTag, genes.team))
		:combineLatest(isLeaderStream, function (team, isLeader)
			return isLeader and Color3.new(0.3, 0.3, 0.3) or team.config.team.color.Value
		end)
		:takeUntil(terminator)
		:subscribe(function (color)
			backpack.state.color.color.Value = color
		end)
end

-- Destroy player backpack
local function destroyPlayerBackpack(player)
	player.state.characterBackpack.destroyed.Value = true
	local instance = player.state.characterBackpack.instance.Value
	if instance then
		instance:Destroy()
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local playerStream = playerUtil.initPlayerGene(characterBackpack)

-- Create instance for each gene
playerStream:subscribe(createBackpack)

-- Destroy backpacks on player left
rx.Observable.from(Players.PlayerRemoving)
	:filter(dart.follow(genesUtil.hasFullState, characterBackpack))
	:subscribe(destroyPlayerBackpack)
