--
--	Jackson Munsell
--	23 Aug 2020
--	activityUtil.lua
--
--	Activity util
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local activities = env.src.activities

-- modules
local dart    = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local activitiesStreams = require(activities.streams)
local EngagementPortal = require(env.src.server.components.activities.EngagementPortal)

-- Create default teams for configs
local Purple = Color3.fromRGB(96, 92, 255)
local Yellow = Color3.fromRGB(250, 255, 153)
local function createDefaultTeams()
	local teams = {}
	teams[1] = {
		Color = Purple,
		DisplayName = "Purple",
	}
	teams[2] = {
		Color = Yellow,
		DisplayName = "Yellow",
	}
	return teams
end

-- Create indicators from roster
local function createIndicatorsFromRoster(roster, teamsConfig)
	local indicators = {}
	for team, players in pairs(roster) do
		for _, player in ipairs(players) do
			local indicator = env.res.axis.PlayerIndicator:Clone()
			indicator.PlayerPointer.Value = player
			indicator.Color = teamsConfig[team].Color
			indicator.Parent = env.ReplicatedStorage
			table.insert(indicators, indicator)
		end
	end
	return indicators
end
local function destroyPlayerIndicators(activity)
	tableau.foreach(activity.playerIndicators or {}, dart.destroy)
	activity.playerIndicators = {}
end
local function cyclePlayerIndicators(activity, config, roster)
	destroyPlayerIndicators(activity)
	activity.playerIndicators = createIndicatorsFromRoster(roster, config.teams)
end

-- Remove player from roster
local function removePlayerFromRoster(rosterSubject, player)
	local newRoster = tableau.duplicate(rosterSubject:getValue())
	for _, list in pairs(newRoster) do
		tableau.removeValue(list, player)
	end
	rosterSubject:push(newRoster)
end

-- Create activity session streams
local function createActivitySessionStreams(_, portal)
	-- Create streams for activity session start and end
	local streams = {
		start = portal.streams.touchedByCabinLeader
			:map(dart.index("Team")),
		stop = activitiesStreams.activityChunkEnded,
	}

	-- Create a state stream out of both of those
	-- 	This stream emits whether or not we are currently in a session
	streams.state = streams.start:map(dart.constant(true))
		:merge(streams.stop:map(dart.constant(false)))
		:startWith(false)

	-- Create an availability stream
	streams.availability = streams.state
		:combineLatest(activitiesStreams.isActivityChunk, function (sessionActive, isActivity)
			return not sessionActive and isActivity
		end)

	-- return
	return streams
end
local function createActivityFromInstance(activityInstance, activityConfig)
	-- New object
	local activity = {}
	activity.instance = activityInstance

	-- Create portal
	activity.portal = EngagementPortal.new(activityInstance)
	activity.portal:setActivityName(activityConfig.DisplayName)

	-- Create session streams
	activity.sessionStreams = createActivitySessionStreams(activityInstance, activity.portal)

	-- Bind portal state to session streams
	activity.sessionStreams.availability:subscribe(dart.bind(EngagementPortal.setActive, activity.portal))

	-- return
	return activity
end

-- return lib
return {
	-- New age functional functions
	createActivitySessionStreams = createActivitySessionStreams,
	createActivityFromInstance   = createActivityFromInstance,
	createIndicatorsFromRoster   = createIndicatorsFromRoster,
	destroyPlayerIndicators   = destroyPlayerIndicators,
	cyclePlayerIndicators   = cyclePlayerIndicators,
	createDefaultTeams   = createDefaultTeams,
	removePlayerFromRoster   = removePlayerFromRoster,
}
