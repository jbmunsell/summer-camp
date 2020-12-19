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

-- Create backpack
local function createBackpack(player)
	-- Create backpack instance
	wait() -- required for weird character spawning timeline
	genesUtil.waitForGene(player, genes.player.jobs)
	local backpack = env.res.character.PlayerBackpack:Clone()
	backpack.Parent = player.Character
	axisUtil.snapAttach(player.Character, backpack, "BodyBackAttachment")
	genesUtil.waitForGene(backpack, genes.color)
	fx.new("ScaleEffect", backpack)
	player.state.characterBackpack.instance.Value = backpack

	-- Terminator stream
	local terminator = rx.Observable.fromInstanceLeftGame(backpack)

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

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local playerStream = playerUtil.initPlayerGene(characterBackpack)

-- Create backpack on character added
playerStream:flatMap(function (player)
	return rx.Observable.from(player.CharacterAdded)
		:startWith(player.Character)
		:filter()
		:map(dart.constant(player))
end):subscribe(createBackpack)
