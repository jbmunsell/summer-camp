--
--	Jackson Munsell
--	11 Nov 2020
--	playerIndicator.server.lua
--
--	playerIndicator gene server driver
--

-- env
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local playerIndicator = genes.playerIndicator

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function createIndicator(player)
	local indicator = env.res.PlayerIndicator:Clone()
	indicator.Parent = workspace
	genesUtil.addGene(indicator, playerIndicator)

	local function setup()
		indicator.state.playerIndicator.player.Value = player
	end
	genesUtil.getInstanceStream(playerIndicator)
		:filter(dart.equals(indicator))
		:subscribe(setup)
end

local function getPlayerIndicator(player)
	return genesUtil.getInstances(playerIndicator)
		:first(function (instance)
			return instance.state.playerIndicator.player.Value == player
		end)
end

local function updateColor(indicator)
	local state = indicator.state.playerIndicator
	state.color.Value = env.config.cabins[state.player.Value.Team.Name].color.Value
end

local function setEnabled(instance, enabled)
	instance.state.playerIndicator.enabled.Value = enabled
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local indicators = genesUtil.initGene(playerIndicator)

-- Tag with fxpart
indicators:subscribe(dart.addTag("FXPart"))

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
	return rx.Observable.fromProperty(player, "Team")
		:startWith(0)
		:map(dart.constant(player))
end):map(getPlayerIndicator)
	:subscribe(updateColor)

-- Indicator should only be enabled if we're in a competitive activity
genesUtil.observeStateValue(playerIndicator, "player")
	:filter(dart.select(2))
	:flatMap(function (instance)
		return genesUtil.getInstanceStream(genes.activity)
			:map(dart.carry(instance))
	end)
	:flatMap(function (instance, activityInstance)
		return collection.observeChanged(activityInstance.state.activity.sessionTeams)
			:map(dart.constant(instance))
	end)
	:map(function (instance)
		return instance, genesUtil.getInstances(genes.activity)
			:first(function (activityInstance)
				local teams = activityInstance.state.activity.sessionTeams
				local playerTeam = instance.state.playerIndicator.player.Value.Team
				return collection.getValue(teams, playerTeam)
			end)
	end)
	:subscribe(setEnabled)
