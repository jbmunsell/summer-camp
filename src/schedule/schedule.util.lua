--
--	Jackson Munsell
--	17 Sep 2020
--	scheduleUtil.lua
--
--	Shared schedule util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local schedule = env.src.schedule
local gui = env.src.gui

-- modules
local dart = require(axis.lib.dart)
local scheduleConfig = require(schedule.config)
local scheduleStreams = require(schedule.streams)
local displayConfig  = require(gui.config)

-- lib
local scheduleUtil = {}

-- Get time string
function scheduleUtil.getTimeString(gameTimeHours)
	local chopDisplay = not displayConfig.display24HourClock
	local hours = math.floor(gameTimeHours); hours = (chopDisplay and (hours - 1) % 12 + 1 or hours)
	local minutes = math.floor(math.fmod(gameTimeHours, 1) * 60)
	local half = (chopDisplay and ((gameTimeHours < 12) and "am" or "pm") or "")
	return string.format("%d:%02d%s", hours, minutes, half)
end

-- Get start time
function scheduleUtil.getChunkStartTime(chunk)
	local t = scheduleConfig.agenda[1].StartingTime
	for _, c in pairs(scheduleConfig.agenda) do
		if c.Index == chunk.Index then break end
		t = t + c.Duration
	end
	return t
end

-- Get time of day stream
function scheduleUtil.getLiveTimeOfDayStream(t)
	return scheduleStreams.gameTime
		:reject(dart.equals(0))
		:map(function (time)
			return time > t
		end)
		:distinctUntilChanged()
		:skip(1)
		:filter()
end
function scheduleUtil.getTimeOfDayStream(t)
	return scheduleStreams.gameTime
		:map(function (time)
			return time > t
		end)
		:startWith(false)
		:distinctUntilChanged()
		:filter()
end

-- return lib
return scheduleUtil
