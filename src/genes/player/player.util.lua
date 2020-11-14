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
local CollectionService = game:GetService("CollectionService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)

-- lib
local playerUtil = {}

-- init player gene
function playerUtil.initPlayerGene(gene)
	-- init gene
	genesUtil.initGene(gene)

	-- If server, wait for each player's first cabin request to add player gene
	if RunService:IsServer() then
		rx.Observable.from(Players.PlayerAdded)
			:startWithTable(Players:GetPlayers())
			:flatMap(function (player)
				return rx.Observable.from(genes.player.team.net.TeamChangeRequested)
					:filter(dart.equals(player))
					:first()
			end)
			:subscribe(function (player, team)
				player.Team = team
				CollectionService:AddTag(player, require(gene.data).instanceTag)
			end)
	end

	-- return stream
	return genesUtil.getInstanceStream(gene)
end

-- return lib
return playerUtil
