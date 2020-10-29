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
local scheduleUtil = require(schedule.util)

-- instances
local ClockFrame = env.PlayerGui:WaitForChild("Core").Container.Clock

-- Set clock time
local function setClockDisplay(timeString)
	ClockFrame.TextLabel.Text = timeString
end

-- Change clock
rx.Observable.from(schedule.interface.GameTimeHours)
	:map(scheduleUtil.getTimeString)
	:subscribe(setClockDisplay)
