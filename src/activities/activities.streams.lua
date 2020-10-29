--
--	Jackson Munsell
--	21 Aug 2020
--	streams.lua
--
--	Activity streams
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local schedule = env.src.schedule

-- modules
local rx = require(axis.lib.rx)
local scheduleStreams = require(schedule.streams)

-- Streams
local isActivityChunk = scheduleStreams.scheduleChunk
	:map(function (chunk)
		return chunk and chunk.Name == "OpenActivityChunk"
	end)
	:distinctUntilChanged()
	:multicast(rx.BehaviorSubject.new(false))
local activityChunkEnded = isActivityChunk
	:skip(1)
	:reject()
	:share()

-- return lib
return {
	isActivityChunk = isActivityChunk,
	activityChunkEnded = activityChunkEnded,
}
