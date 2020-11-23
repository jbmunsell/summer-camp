--
--	Jackson Munsell
--	22 Nov 2020
--	job.server.lua
--
--	job gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local playerUtil = require(genes.player.util)
local jobUtil = require(genes.player.job.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local playerStream = playerUtil.hardInitPlayerGene(genes.player.job)
local jobCharacterStream = playerStream:flatMap(function (player)
	return rx.Observable.from(player.CharacterAdded)
		:startWith(player.Character)
		:filter()
		:map(dart.constant(player))
end)

-- Job changed stream
local jobChanged = genesUtil.observeStateValue(genes.player.job, "job")
local wearClothesChanged = genesUtil.observeStateValue(genes.player.job, "wearClothes")

-- Render character when added AND when job changed AND when wearClothes changed
jobChanged:merge(jobCharacterStream, wearClothesChanged):subscribe(jobUtil.renderPlayerCharacter)

-- Render gear when job is changed
jobChanged:subscribe(jobUtil.giveJobGear)
