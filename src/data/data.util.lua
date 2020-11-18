--
--	Jackson Munsell
--	09 Nov 2020
--	data.util.lua
--
--	Data util
--

-- env
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)

-- lib
local dataUtil = {}

-- Add player state
function dataUtil.addPlayerState(player, stateName, state)
	if not player:FindFirstChild("state") then
		Instance.new("Folder", player).Name = "state"
	end
	tableau.tableToValueObjects(stateName, state).Parent = player.state
end

-- Player has state
function dataUtil.playerHasState(player, stateName)
	return player:FindFirstChild("state") and player.state:FindFirstChild(stateName)
end

-- Wait for state
function dataUtil.waitForGene(player, stateName)
	return player:WaitForChild("state"):WaitForChild(stateName)
end

-- Register player state
-- 	This will subscribe to an observable that creates such state for all
-- 	players, and returns a stream of players with the state added
function dataUtil.registerPlayerState(stateName, state)
	-- Add state folder on player added
	local playerStream = rx.Observable.from(Players.PlayerAdded)
		:startWithTable(Players:GetPlayers())
	playerStream:subscribe(dart.follow(dataUtil.addPlayerState, stateName, state))

	-- Create stream where state has been registered
	return playerStream
		:map(function (player)
			dataUtil.waitForGene(player, stateName)
			return player
		end)
end

-- return lib
return dataUtil
