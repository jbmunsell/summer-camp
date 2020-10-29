--
--	Jackson Munsell
--	19 Aug 2020
--	schedule.server.lua
--
--	Server schedule driver - handles all things relating to time
-- 		management and scheduling
--

-- env
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local schedule = env.src.schedule
local notifications = env.src.gui.notifications
local objects = env.src.objects
local mattress = objects.mattress

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local scheduleStreams = require(schedule.streams)
local scheduleConfig = require(schedule.config)
local mattressConfig = require(mattress.config)
local objectsUtil = require(objects.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Fire chunk changed
local function fireChunkChanged(chunk)
	-- Print to output
	print("Schedule chunk changed")
	print("\tNew chunk: " .. tostring(chunk.Name))

	-- Fire remote event
	schedule.net.ChunkChanged:FireAllClients(chunk)

	-- Get config folder and send notification to all clients
	if chunk.StartMessage then
		notifications.net.Push:FireAllClients(chunk.StartMessage)
	end
end

-- Update lighting according to game time
local function updateLighting(gameTimeHours)
	-- Adjust lighting
	Lighting:SetMinutesAfterMidnight(gameTimeHours * 60)

	-- Export game time to a replicated value
	schedule.interface.GameTimeHours.Value = gameTimeHours
end

-- Get players in bed
local function getNightTimeScaleModifier()
	-- No players
	local numPlayers = #Players:GetPlayers()
	if numPlayers <= 0 then
		return scheduleConfig.NightScaleFlat
	end

	-- Count players in mattresses
	local inBed = objectsUtil.getObjects(mattress)
		:map(dart.index("state", "mattress", "owner", "value"))
		:filter()
		:size()

	-- Return interpolated value
	local f = (inBed / numPlayers)
	local flat = scheduleConfig.NightScaleFlat
	local full = scheduleConfig.NightScaleFull
	return flat + f * (full - flat)
end

-- Tween time scale to a new value
-- 	Using instant setting is very jarring in the transition from night to day
-- 	and day to night.
local function tweenTimeScale(target)
	TweenService:Create(schedule.interface.GameTimeScale, scheduleConfig.TimeScaleTweenInfo, { Value = target }):Play()
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Connect remote function to return value
schedule.net.GetCurrentChunk.OnServerInvoke = function ()
	return scheduleStreams.scheduleChunk:getValue()
end

-- Send to clients chunk changed
scheduleStreams.scheduleChunk
	:subscribe(fireChunkChanged)

-- Adjust lighting settings when game clock changes
scheduleStreams.gameTime
	:subscribe(updateLighting)

-- Adjust game time scale according to whether or not we're a night chunk
-- 	and according to the number of players in their beds
local function isNight(chunk) return chunk and chunk.Name == "LightsOut" end
local nightStart, nightStop = scheduleStreams.scheduleChunk
	:partition(isNight)

nightStart = nightStart
	:map(getNightTimeScaleModifier)
nightStop = nightStop
	:distinctUntilChanged()
	:map(dart.constant(scheduleConfig.DaytimeScale))
local mattressesChanged = rx.Observable.fromInstanceTag(mattressConfig.instanceTag)
	:flatMap(function (mattressInstance)
		return rx.Observable.from(mattressInstance.state.mattress.owner)
	end)
	:filter(isNight)
	:map(getNightTimeScaleModifier)

mattressesChanged:merge(nightStart, nightStop)
	:subscribe(tweenTimeScale)

