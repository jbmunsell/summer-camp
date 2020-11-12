--
--	streams.lua
--	19 Aug 2020
--	streams.lua
--
--	Schedule-related streams
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local schedule = env.src.schedule

-- modules
local rx = require(axis.lib.rx)
local scheduleConfig = require(schedule.config)

-- Game time
local gameTime = rx.Observable.from(schedule.interface.GameTimeHours)

-- 	Current chunk tracker stream
local currentChunkTracker = gameTime
	:map(function (t)
		local chunkEndTime = scheduleConfig.agenda[1].StartingTime
		for _, chunk in pairs(scheduleConfig.agenda) do
			chunkEndTime = chunkEndTime + chunk.Duration
			if chunkEndTime >= t then
				return chunk, chunkEndTime, t
			end
		end
	end)
	:multicast(rx.BehaviorSubject.new())

-- 	Chunk time left
-- 	(float realLifeSecondsLeft)
local chunkTimeLeft = currentChunkTracker
	:skip(1)
	:map(function (_, chunkEndTime, t)
		-- Convert to REAL LIFE SECONDS
		return (chunkEndTime - t) * (1 / schedule.interface.GameTimeScale.Value)
	end)
	:multicast(rx.BehaviorSubject.new(0))

-- 	Schedule chunk changed
local scheduleChunk = currentChunkTracker
	:distinctUntilChanged(function (old, new)
		return (old and old.Name) == (new and new.Name)
	end)
	:filter()
	:multicast(rx.BehaviorSubject.new())

-- streams
return {
	gameTime = gameTime,
	scheduleChunk = scheduleChunk,
	chunkTimeLeft = chunkTimeLeft,
}
