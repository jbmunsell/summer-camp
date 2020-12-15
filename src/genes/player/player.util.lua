--
--	Jackson Munsell
--	13 Nov 2020
--	player.util.lua
--
--	player gene util
--

-- env
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local genesUtil = require(genes.util)

-- lib
local playerUtil = {}

-- init player gene
function playerUtil.initPlayerGene(gene)
	-- init gene
	genesUtil.initGene(gene)
	print("initializing " .. tostring(gene))

	-- If server, wait for each player's first cabin request to add player gene
	if RunService:IsServer() then
		local obs = rx.Observable.from(Players.PlayerAdded)
			:startWithTable(Players:GetPlayers())

		obs:subscribe(function (player)
			genesUtil.addGeneTag(player, gene)
		end)
	end

	-- return stream
	return genesUtil.getInstanceStream(gene)
end

-- return lib
return playerUtil
