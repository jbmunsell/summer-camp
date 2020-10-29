--
--	Jackson Munsell
--	17 Sep 2020
--	scheduleUtil.lua
--
--	Shared schedule util
--

-- env
local env      = require(game:GetService("ReplicatedStorage").src.env)
local schedule = env.src.schedule
local gui      = env.src.gui

-- modules
local scheduleConfig = require(schedule.config)
local displayConfig  = require(gui.config)

-- Get time string
local function getTimeString(gameTimeHours)
	local chopDisplay = not displayConfig.display24HourClock
	local hours = math.floor(gameTimeHours); hours = (chopDisplay and (hours - 1) % 12 + 1 or hours)
	local minutes = math.floor(math.fmod(gameTimeHours, 1) * 60)
	local half = (chopDisplay and ((gameTimeHours < 12) and "am" or "pm") or "")
	return string.format("%d:%02d%s", hours, minutes, half)
end

-- Get start time
local function getChunkStartTime(chunk)
	local t = scheduleConfig.agenda[1].StartingTime
	for _, c in pairs(scheduleConfig.agenda) do
		if c.Index == chunk.Index then break end
		t = t + c.Duration
	end
	return t
end

-- return lib
return {
	getTimeString = getTimeString,
	getChunkStartTime = getChunkStartTime,
}
