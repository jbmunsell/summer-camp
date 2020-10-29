--
--	Jackson Munsell
--	13 Sep 2020
--	ragdoll.server.lua
--
--	Ragdoll server driver
--

-- env
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local Ragdoll = env.packages.Ragdoll

-- modules
require(Ragdoll)
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local buildRagdoll = require(Ragdoll.buildRagdoll)

-- init player character
local function initPlayerCharacter(player, character)
	-- Weird necessary wait
	if not player:HasAppearanceLoaded() then
		player.CharacterAppearanceLoaded:wait()
		wait(0.1)
	end

	-- Build ragdoll
	buildRagdoll(character:WaitForChild("Humanoid"))
end

-- Build ragdoll for all player characters
rx.Observable.from(Players.PlayerAdded)
	:startWithTable(Players:GetPlayers())
	:flatMap(function (player)
		return rx.Observable.from(player.CharacterAdded)
			:startWith(player.Character)
			:filter()
			:map(dart.carry(player))
	end)
	:subscribe(coroutine.wrap(initPlayerCharacter))
