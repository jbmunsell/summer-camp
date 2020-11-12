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
