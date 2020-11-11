--
--	Jackson Munsell
--	10 Nov 2020
--	soccer.server.lua
--
--	soccer activity gene server driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local activity = genes.activity
local soccer = activity.soccer

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local activityUtil = require(activity.util)
local scoreboardUtil = require(genes.scoreboard.util)
local scheduleStreams = require(env.src.schedule.streams)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Factory functions
local function makeSetStateValue(valueName, value)
	return function (soccerInstance)
		soccerInstance.state.soccer[valueName].Value = value
	end
end

-- Quick accessors
local function isVolleyActive(soccerInstance)
	return soccerInstance.state.soccer.volleyActive.Value
end
local startMatch = makeSetStateValue("matchActive", true)
local stopMatch = makeSetStateValue("matchActive", false)
local startVolley = makeSetStateValue("volleyActive", true)
local stopVolley = makeSetStateValue("volleyActive", false)

-- Score manipulation
local function resetScore(instance)
	tableau.from(instance.state.soccer.score:GetChildren())
		:foreach(dart.setValue(0))
end
local function increaseScore(soccerInstance, scoringTeam)
	local valueObject = soccerInstance.state.soccer.score[scoringTeam]
	valueObject.Value = valueObject.Value + 1
end

-- Ball manipulation
local function isBallInBounds(soccerInstance)
	local functional = soccerInstance.functional
	local ball = functional:FindFirstChild("Ball")
	return ball and axisUtil.isPointInPartXZ(ball.Position, functional.PitchBounds)
end
local function getBallInGoalScoringTeam(soccerInstance)
	local functional = soccerInstance.functional
	local ball = functional:FindFirstChild("Ball")
	if ball then
		for i = 1, 2 do
			local goalPart = functional["Team" .. i .. "GoalSensor"]
			if axisUtil.isPointInPart(ball.Position, goalPart) then
				return 3 - i
			end
		end
	end
	return nil
end
local function respawnBall(soccerInstance)
	-- Clear old
	local functional = soccerInstance.functional
	axisUtil.destroyChild(functional, "Ball")

	-- Create new
	local ball = soccerInstance.config.soccer.ball.Value:Clone()
	ball.Name = "Ball"
	ball.CFrame = functional.BallSpawn.CFrame
	ball.Velocity = Vector3.new()
	ball.Parent = functional
end

-- Rendering
local function updateScoreboardTeams(soccerInstance)
	scoreboardUtil.setTeams(soccerInstance.Scoreboard, soccerInstance.state.activity.sessionTeams)
end
local function updateScoreboardScore(soccerInstance)
	local score = tableau.valueObjectsToTable(soccerInstance.state.soccer.score)
	tableau.log(score)
	scoreboardUtil.setScore(soccerInstance.Scoreboard, score)
end
local function updateScoreboardTime(soccerInstance, secondsRemaining)
	scoreboardUtil.setTime(soccerInstance.Scoreboard, secondsRemaining)
end
local function placePlayersOnPitch(soccerInstance)
	local functional = soccerInstance.functional
	for i = 1, 2 do
		local spawnPlane = functional["Team" .. i .. "SpawnPlane"]
		local players = soccerInstance.state.activity.sessionTeams[i].Value:GetPlayers()
		activityUtil.spawnPlayersInPlane(players, spawnPlane, functional.BallSpawn.Position)
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local soccerInstances = genesUtil.initGene(soccer)

-- Split and select operator
local function splitAndSelect(observable)
	local sel = dart.select(1)
	local a, b = observable:partition(dart.select(2))
	return a:map(sel), b:map(sel)
end

-- Various score streams
local function getTeamScoreStream(teamIndex)
	return soccerInstances
		:flatMap(function (instance)
			return rx.Observable.from(instance.state.soccer.score[teamIndex])
				:map(dart.carry(instance, teamIndex))
		end)
end
local baseScoreStream = getTeamScoreStream(1):merge(getTeamScoreStream(2))
local teamScoredStream = baseScoreStream
	:reject(function (_, _, score) return score == 0 end) -- filter out score reset events
local plainGoalStream, winningGoalStream = teamScoredStream
	:partition(function (instance, _, score)
		return score < instance.config.soccer.goalsToWin.Value
	end)

-- Activity session start
local sessionStartStream, sessionEndStream = genesUtil.crossObserveStateValue(soccer, activity, "inSession")
	:pipe(splitAndSelect)

-- Match state streams
local matchStartStream, matchEndStream = genesUtil.observeStateValue(soccer, "matchActive")
	:pipe(splitAndSelect)

-- Volley state streams
local volleyStartStream, _ = genesUtil.observeStateValue(soccer, "volleyActive")
	:pipe(splitAndSelect)

-- Heartbeat of soccer instances where volley is active
local volleyActivePulse = rx.Observable.heartbeat()
	:map(dart.bind(genesUtil.getInstances, soccer))
	:flatMap(rx.Observable.from)
	:filter(isVolleyActive)

-- Ball escaped bounds of its pitch
local ballEscapedStream = volleyActivePulse
	:reject(isBallInBounds)

-----------------------------------
-- Match state subscriptions
-- START MATCH when old match ends OR when new activity session begins
matchEndStream
	:delay(3)
	:filter(activityUtil.isInSession)
	:merge(sessionStartStream)
	:subscribe(startMatch)

-- STOP MATCH after winning goal is scored OR session terminates
winningGoalStream
	:merge(sessionEndStream)
	:subscribe(stopMatch)

-----------------------------------
-- Volley state subscriptions
-- START VOLLEY when match starts OR on plain goal delay finished
plainGoalStream
	:delay(3)
	:filter(activityUtil.isInSession)
	:merge(matchStartStream)
	:subscribe(startVolley)

-- STOP VOLLEY when any goal is scored OR session terminates
teamScoredStream
	:merge(sessionEndStream)
	:subscribe(stopVolley)

-----------------------------------
-- Ball subscriptions
-- Respawn ball when it escapes OR volley starts
ballEscapedStream:merge(volleyStartStream)
	:subscribe(respawnBall)

-----------------------------------
-- Score manipulation subscriptions
-- Increase score when ball is in goal
volleyActivePulse
	:map(function (soccerInstance)
		return soccerInstance, getBallInGoalScoringTeam(soccerInstance)
	end)
	:filter(dart.select(2))
	:subscribe(increaseScore)

-- Reset score when match begins
matchStartStream:subscribe(resetScore)

-----------------------------------
-- Scoreboard subscriptions
-- Set teams on match start
matchStartStream:subscribe(updateScoreboardTeams)

-- Update scoreboard when score changes
baseScoreStream:map(dart.select(1)):subscribe(updateScoreboardScore)

-- Update scoreboard time when time changes
scheduleStreams.chunkTimeLeft
	:filter(activityUtil.isActivityChunk)
	:flatMap(function (t)
		return rx.Observable.from(genesUtil.getInstances(soccer))
			:map(dart.drag(t))
	end)
	:subscribe(updateScoreboardTime)

-----------------------------------
-- Player placement subscriptions
volleyStartStream:subscribe(placePlayersOnPitch)
