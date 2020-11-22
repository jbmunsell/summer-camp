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
local genes = env.src.genes
local mattress = genes.mattress

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local scheduleStreams = require(schedule.streams)
local scheduleConfig = require(schedule.config)
local genesUtil = require(genes.util)

---------------------------------------------------------------------------------------------------
-- Instances
---------------------------------------------------------------------------------------------------

env.res.audio.sounds:Clone().Parent = workspace

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

	-- Play sound!
	workspace.sounds.ScheduleBell:Play()

	-- Get config folder and send notification to all clients
	if chunk.StartMessage then
		notifications.net.Push:FireAllClients(chunk.StartMessage)
	end
end

-- Update lighting according to game time
local function setGameTimeValue(t)
	Lighting:SetMinutesAfterMidnight(t * 60)
	schedule.interface.GameTimeHours.Value = t
end

-- Get players in bed
local function getNightTimeScaleModifier()
	-- No players
	local numPlayers = #Players:GetPlayers()
	if numPlayers <= 0 then
		return scheduleConfig.NightScaleFlat
	end

	-- Count players in mattresses
	local inBed = genesUtil.getInstances(mattress)
		:map(function (instance)
			return instance.state.humanoidHolder.owner.Value
		end)
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
	print("Tweening to " .. target)
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

-- 	Game time changed
-- 	(float gameTime)
-- 		gameTime - the current time of day (hours since midnight) in the game; 0 thru 24
local scale = schedule.interface.GameTimeScale
rx.Observable.heartbeat()
	:scan(function (t, dt)
		return (t + dt * scale.Value) % 24
	end, scheduleConfig.StartingGameTime)
	:subscribe(setGameTimeValue)

-- Adjust game time scale according to whether or not we're a night chunk
-- 	and according to the number of players in their beds
local function isNight() return scheduleStreams.scheduleChunk:getValue().Name == "LightsOut" end
local nightStart, nightStop = scheduleStreams.scheduleChunk
	:partition(isNight)

nightStart = nightStart
	:tap(dart.printConstant("night start"))
	:map(getNightTimeScaleModifier)
nightStop = nightStop
	:distinctUntilChanged()
	:map(dart.constant(scheduleConfig.DaytimeScale))
local mattressesChanged = genesUtil.getInstanceStream(mattress)
	:flatMap(function (mattressInstance)
		return rx.Observable.from(mattressInstance.state.humanoidHolder.owner)
	end)
	:filter(isNight)
	:map(getNightTimeScaleModifier)

mattressesChanged:merge(nightStart, nightStop)
	:subscribe(tweenTimeScale)

