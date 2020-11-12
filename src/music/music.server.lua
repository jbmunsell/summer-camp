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

-- modules
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local scheduleStreams = require(env.src.schedule.streams)

-- Variables
local VolumeTweenInfo = TweenInfo.new(5.0)

-- Clone sounds into workspace
env.res.audio:Clone().Parent = workspace
tableau.from(workspace.audio:GetChildren()):foreach(function (sound)
	sound:Play()
	sound.Volume = 0
end)

-- Play track
local function fade(sound, up)
	TweenService:Create(sound, VolumeTweenInfo, { Volume = (up and 0.6 or 0) }):Play()
end
local function playTrack(track)
	tableau.from(workspace.audio:GetChildren())
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
local dayStartStream = fromTimeStream(8)
local dayEndStream = fromTimeStream(18)

dayStartStream:map(dart.constant(workspace.audio.DayTrack))
	:merge(dayEndStream:map(dart.constant(workspace.audio.NightTrack)))
	:subscribe(playTrack)
