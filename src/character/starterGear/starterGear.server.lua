--
--	Jackson Munsell
--	16 Dec 2020
--	starterGear.server.lua
--
--	Server driver to give players starter gear
--

-- env
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local pickupUtil = require(genes.pickup.util)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

local function givePlayerStarterGear(player)
	for _, gear in pairs(env.res.starterGear:GetChildren()) do
		local copy = gear:Clone()
		if genesUtil.hasGeneTag(copy, genes.playerProperty) then
			copy.state.playerProperty.owner.Value = player
		end
		copy.Parent = ReplicatedStorage
		genesUtil.waitForGene(copy, genes.pickup)
		pickupUtil.stowObjectForPlayer(player, copy)
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

rx.Observable.from(Players.PlayerAdded)
	:startWithTable(Players:GetPlayers())
	:subscribe(function (player)
		spawn(function ()
			givePlayerStarterGear(player)
		end)
	end)
