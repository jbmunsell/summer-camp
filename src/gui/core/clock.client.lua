--
--	Jackson Munsell
--	14 Sep 2020
--	clock.client.lua
--
--	CoreGui.Clock client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local schedule = env.src.schedule

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local scheduleUtil = require(schedule.util)
local scheduleStreams = require(schedule.streams)

-- instances
local ClockFrame = env.PlayerGui:WaitForChild("Core").Container.Clock

-- Set clock time
local function setClockDisplay(timeString)
	ClockFrame.TextLabel.Text = timeString
end

-- Set activity text
local function setActivityText(text)
	ClockFrame.Activity.TextLabel.Text = text
end

-- Change clock
rx.Observable.from(schedule.interface.GameTimeHours)
	:map(scheduleUtil.getTimeString)
	:subscribe(setClockDisplay)

-- Change schedule chunk
scheduleStreams.scheduleChunk:map(dart.index("DisplayName"))
	:subscribe(setActivityText)
