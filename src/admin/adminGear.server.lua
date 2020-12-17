--
--	Jackson Munsell
--	17 Dec 2020
--	adminGear.server.lua
--
--	admin gear server driver
--

-- env
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)

---------------------------------------------------------------------------------------------------
-- Give admin gear to admins
---------------------------------------------------------------------------------------------------

local function isAdmin(player)
	return collection.getValue(env.config.admins, player.UserId) or RunService:IsStudio()
end

rx.Observable.from(Players.PlayerAdded)
	:startWithTable(Players:GetPlayers())
	:filter(isAdmin)
	:subscribe(function (player)
		for _, gear in pairs(env.res.adminGear:GetChildren()) do
			local copy = gear:Clone()
			copy.Parent = ReplicatedStorage
			genesUtil.waitForGene(copy, genes.pickup)
			pickupUtil.stowObjectForPlayer(player, copy)
		end
	end)
