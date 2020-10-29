--
--	Jackson Munsell
--	17 Sep 2020
--	schedule.client.lua
--
--	Schedule gui client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local schedule = env.src.schedule

-- modules
local rx   = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local glib = require(axis.lib.glib)
local scheduleConfig = require(schedule.config)
local scheduleUtil   = require(schedule.util)

-- instances
local Core = env.PlayerGui:WaitForChild("Core")
local ScheduleFrame = Core.Container.Schedule.Background
local ScheduleMenuButton = Core.Container.MenuButtons.Schedule
local seeds = Core.seeds
local animations = Core.animations

-- Set visible
local function setVisible(visible, instant)
	glib.playAnimation(animations.schedule[visible and "show" or "hide"], ScheduleFrame, instant)
end

-- Construct and render schedule
local function constructSchedule()
	-- Clear layout
	glib.clearLayoutContents(ScheduleFrame.Times)
	glib.clearLayoutContents(ScheduleFrame.Activities)

	-- Iterate each chunk and create proper elements
	for i, chunk in pairs(scheduleConfig.agenda) do
		-- Create a time label
		local timeLabel = seeds.schedule.TimeLabel:Clone()
		timeLabel.Text = scheduleUtil.getTimeString(scheduleUtil.getChunkStartTime(chunk))
		timeLabel.LayoutOrder = i
		timeLabel.Name = tostring(i)
		timeLabel.Parent = ScheduleFrame.Times
		timeLabel.Visible = true

		-- Create an activity label
		local activityLabel = seeds.schedule.ActivityLabel:Clone()
		activityLabel.Text = chunk.DisplayName
		activityLabel.LayoutOrder = i
		activityLabel.Name = tostring(i)
		activityLabel.StrikeThrough.Rotation = math.random(-3, 3)
		activityLabel.Parent = ScheduleFrame.Activities
		activityLabel.Visible = true
	end
end
local function setChunkIndexComplete(chunkIndex, complete, instant)
	local anim = animations.schedule[complete and "chunkComplete" or "chunkIncomplete"]
	glib.playAnimation(anim, ScheduleFrame, instant, chunkIndex)
end
local function renderSchedule(currentChunk, instant)
	for i, _ in pairs(scheduleConfig.agenda) do
		setChunkIndexComplete(i, (i < currentChunk.Index), instant)
	end
end

-- Create open and close stream
rx.Observable.from(ScheduleMenuButton.Button.Activated)
	:scan(dart.boolNot, false)
	:startWithArgs(false, true)
	:subscribe(setVisible)
ScheduleFrame.Parent.Visible = true

-- Render schedule stream
constructSchedule()
rx.Observable.from(schedule.net.ChunkChanged)
	:startWithArgs(schedule.net.GetCurrentChunk:InvokeServer(), true)
	:subscribe(renderSchedule)
