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
local axisUtil = require(axis.lib.axisUtil)
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)
local playerUtil = require(genes.player.util)
local jobUtil = require(genes.job.util)
local jobsUtil = require(genes.player.jobs.util)
local scheduleUtil = require(env.src.schedule.util)

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
local outfitsEnabledChanged = genesUtil.observeStateValue(genes.player.jobs, "outfitsEnabled")

-- Render character when added AND when job changed AND when outfitsEnabled changed
jobChanged:merge(jobCharacterStream, outfitsEnabledChanged)
	:throttle(0.1) -- they will usually fire in quick succession
	:subscribe(jobsUtil.renderPlayerCharacter)

-- Render gear when job is changed
jobChanged:subscribe(jobsUtil.givePlayerJobGear)

-- Keep track of a player's loaded avatar
playerStream:subscribe(function (player)
	rx.Observable.from(player.CharacterAppearanceLoaded)
		:startWith(player:HasAppearanceLoaded())
		:filter()
		:subscribe(function ()
			axisUtil.destroyChild(player.state.jobs, "playerDescription")
			local desc = player.Character.Humanoid:GetAppliedDescription():Clone()
			desc.Parent = player.state.jobs
			desc.Name = "playerDescription"
		end)
end)

-- Give player daily job gear at the start of the day OR when they switch
-- 	UNLESS they have already received it
local dayStartStream = rx.BehaviorSubject.new()
scheduleUtil.getTimeOfDayStream(6):subscribe(function ()
	genesUtil.getInstances(genes.player.jobs):foreach(function (player)
		collection.clear(player.state.jobs.dailyGearGiven)
	end)
	dayStartStream:push()
end)
jobChanged:merge(dayStartStream:skip(1):flatMap(function ()
	return rx.Observable.from(genesUtil.getInstances(genes.player.jobs))
		:map(function (player)
			return player, player.state.jobs.job.Value
		end)
		:filter(dart.select(2))
end)):reject(function (player, job)
	return collection.getValue(player.state.jobs.dailyGearGiven, job)
end):subscribe(jobsUtil.givePlayerJobDailyGear)

-- Track player unlocked jobs
playerStream:subscribe(function (player)
	for _, instance in pairs(genesUtil.getInstances(genes.job):raw()) do
		local gamepassId = instance.config.job.gamepassId.Value
		if gamepassId == 0 or MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId) then
			collection.addValue(player.state.jobs.unlocked, instance)
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

-- Forward job requests
rx.Observable.from(genes.player.jobs.net.JobChangeRequested)
	:filter(function (player, job)
		return collection.getValue(player.state.jobs.unlocked, job)
	end)
	:subscribe(function (player, job, outfitsEnabled, scale)
		local state = player.state.jobs
		state.outfitsEnabled.Value = outfitsEnabled
		state.job.Value = job
		state.avatarScale.Value = scale
	end)
