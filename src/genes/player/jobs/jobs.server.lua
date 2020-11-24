--
--	Jackson Munsell
--	22 Nov 2020
--	jobs.server.lua
--
--	jobs gene server driver
--

-- env
local MarketplaceService = game:GetService("MarketplaceService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)
local playerUtil = require(genes.player.util)
local jobUtil = require(genes.job.util)
local jobsUtil = require(genes.player.jobs.util)

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local playerStream = playerUtil.hardInitPlayerGene(genes.player.jobs)
local jobCharacterStream = playerStream:flatMap(function (player)
	return rx.Observable.from(player.CharacterAdded)
		:startWith(player.Character)
		:filter()
		:map(dart.constant(player))
end)

-- Job changed stream
local jobChanged = genesUtil.observeStateValue(genes.player.jobs, "job")
local wearClothesChanged = genesUtil.observeStateValue(genes.player.jobs, "wearClothes")

-- Render character when added AND when job changed AND when wearClothes changed
jobChanged:merge(jobCharacterStream, wearClothesChanged):subscribe(jobsUtil.renderPlayerCharacter)

-- Render gear when job is changed
jobChanged:subscribe(jobsUtil.giveJobGear)

-- Track player unlocked jobs
playerStream:subscribe(function (player)
	for _, instance in pairs(genesUtil.getInstances(genes.job):raw()) do
		local gamepassId = instance.config.job.gamepassId.Value
		if gamepassId ~= 0 then
			if MarketplaceService:UserOwnsGamepassAsync(player, gamepassId) then
				collection.addValue(player.state.jobs.unlocked, instance)
			end
		end
	end
end)
rx.Observable.from(MarketplaceService.PromptGamePassPurchaseFinished)
	:subscribe(function (player, gamepassId, wasPurchased)
		local job = jobUtil.getJobFromGamepassId(gamepassId)
		if job and wasPurchased then
			collection.addValue(player.state.jobs.unlocked, job)
		end
	end)
