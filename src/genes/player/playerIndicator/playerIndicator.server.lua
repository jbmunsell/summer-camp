--
--	Jackson Munsell
--	11 Nov 2020
--	playerIndicator.server.lua
--
--	playerIndicator gene server driver
--

-- env
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local playerIndicator = genes.player.playerIndicator

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local activityUtil = require(genes.activity.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function createIndicator(player)
	local indicator = env.res.PlayerIndicator:Clone()
	indicator.Parent = workspace
	genesUtil.addGeneTag(indicator, playerIndicator)
	genesUtil.waitForGene(indicator, playerIndicator)
	indicator.state.playerIndicator.player.Value = player
end

local function getPlayerIndicator(player)
	return genesUtil.getInstances(playerIndicator)
		:first(function (instance)
			return instance.state.playerIndicator.player.Value == player
		end)
end

local function setTeam(indicator, team)
	genesUtil.waitForGene(indicator, genes.teamLink)
	indicator.state.teamLink.team.Value = team
end

local function setEnabled(instance, enabled)
	instance.state.playerIndicator.enabled.Value = enabled
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
genesUtil.initGene(playerIndicator)

-- Create one for each player on entry
local players = rx.Observable.from(Players.PlayerAdded)
	:startWithTable(Players:GetPlayers())
players:subscribe(createIndicator)

-- Destroy on player left
rx.Observable.from(Players.PlayerRemoving)
	:map(getPlayerIndicator)
	:subscribe(dart.destroy)

-- Set color on team changed
players:flatMap(function (player)
	return rx.Observable.fromProperty(player, "Team", true)
		:map(dart.constant(player))
end):map(getPlayerIndicator)
	:filter()
	:merge(genesUtil.observeStateValue(playerIndicator, "player"):filter(dart.select(2)))
	:map(function (indicator)
		local team = indicator.state.playerIndicator.player.Value.Team
		return indicator, (genesUtil.hasGeneTag(team, genes.team) and team)
	end)
	:filter(dart.select(2))
	:subscribe(setTeam)

-- Indicator should only be enabled if we're in a competitive activity
genesUtil.observeStateValue(playerIndicator, "player")
	:filter(dart.select(2))
	:flatMap(function (instance, player)
		return activityUtil.getPlayerCompetingStream(player)
			:map(dart.carry(instance))
	end)
	:subscribe(setEnabled)
