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
local function initPlayerGene(gene, waitForTeam)
	-- init gene
	genesUtil.initGene(gene)

	-- If server, wait for each player's first cabin request to add player gene
	if RunService:IsServer() then
		local obs = rx.Observable.from(Players.PlayerAdded)
			:startWithTable(Players:GetPlayers())
		if waitForTeam then
			obs = obs:flatMap(function (player)
				return rx.Observable.fromProperty(player, "Team", true)
					:filter(dart.follow(genesUtil.hasGeneTag, genes.team))
					:map(dart.constant(player))
					:first()
			end)
		end

		obs:subscribe(function (player)
			CollectionService:AddTag(player, require(gene.data).instanceTag)
		end)
	end

	-- return stream
	return genesUtil.getInstanceStream(gene)
end

-- init player gene AFTER they select a team
function playerUtil.softInitPlayerGene(gene)
	return initPlayerGene(gene, true)
end

-- hard init player gene
function playerUtil.hardInitPlayerGene(gene)
	return initPlayerGene(gene, false)
end

-- return lib
return playerUtil
