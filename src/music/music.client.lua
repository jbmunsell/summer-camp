--
--	Jackson Munsell
--	12 Nov 2020
--	music.server.lua
--
--	Music server driver
--

-- env
local TweenService = game:GetService("TweenService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local scheduleStreams = require(env.src.schedule.streams)
local genesUtil = require(genes.util)
local activityUtil = require(env.src.genes.activity.util)

-- Variables
local VolumeTweenInfo = TweenInfo.new(5.0)

-- Clone sounds into workspace
env.res.audio.ambientTracks:Clone().Parent = workspace
env.res.audio.ambientSounds:Clone().Parent = workspace
local tracks = workspace.ambientTracks
tableau.from(tracks:GetChildren()):foreach(function (sound)
	sound:Play()
	sound.Volume = 0
end)

-- Play track
local function fade(sound, up)
	TweenService:Create(sound, VolumeTweenInfo, { Volume = (up and sound.FullVolume.Value or 0) }):Play()
end
local function playTrack(track)
	tableau.from(tracks:GetChildren())
		:reject(dart.equals(track))
		:foreach(dart.follow(fade, false))
	fade(track, true)
end

-- Play according to time of day
local function fromTimeStream(t)
	return scheduleStreams.gameTime
		:map(function (time)
			return time > t
		end)
		:startWith(false)
		:distinctUntilChanged()
		:filter()
end
local dayStartStream = fromTimeStream(6)
local dayEndStream = fromTimeStream(18)

local isDayStream = dayStartStream:map(dart.constant(true))
	:merge(dayEndStream:map(dart.constant(false)))

-- Track priority:
-- 	1. Menu music
-- 	2. Competitive
-- 	3. Day / night music
local menuEnabledStream = rx.Observable.fromProperty(env.PlayerGui:WaitForChild("SplashScreen"), "Enabled", true)
local isCompetingStream = activityUtil.getPlayerActivityStream(env.LocalPlayer):startWith(false)
isCompetingStream:combineLatest(menuEnabledStream, isDayStream, function (activityInstance, menuEnabled, isDay)
	if menuEnabled then
		return tracks.MenuTrack
	end

	local activityTrack
	if activityInstance then
		if genesUtil.hasGeneTag(activityInstance, genes.activity.captureTheFlag) then
			activityTrack = tracks.CTFTrack
		else
			activityTrack = tracks.CompetitiveTrack
		end
	end
	return (activityTrack or (isDay and tracks.DayTrack or tracks.NightTrack))
end):subscribe(playTrack)

-- Attach crickets to night track
rx.Observable.fromProperty(tracks.NightTrack, "Volume", true):subscribe(function (v)
	workspace.ambientSounds.Crickets.Volume = v
end)
