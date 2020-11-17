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
local soundUtil = require(axis.lib.soundUtil)
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
local startVolley = makeSetStateValue("volleyActive", true)
local stopVolley = makeSetStateValue("volleyActive", false)

-- Cannon firing
local function fireCannonsForTeam(soccerInstance, teamIndex)
	local team = soccerInstance.state.activity.sessionTeams[teamIndex].Value
	local descendants = tableau.from(soccerInstance:GetDescendants())
	descendants:filter(dart.isNamed("ConfettiiTeam")):foreach(function (emitter)
		emitter.Color = ColorSequence.new(team.config.team.color.Value)
		emitter:Emit(50)
	end)
	descendants:filter(dart.isNamed("ConfettiiGold"))
		:foreach(function (emitter)
			emitter:Emit(50)
		end)
end

-- Score manipulation
local function increaseScore(soccerInstance, scoringTeam)
	local valueObject = soccerInstance.state.activity.score[scoringTeam]
	valueObject.Value = valueObject.Value + 1
	local sound = soundUtil.playSound(env.res.audio.sounds.soccer.GoalScored,
		soccerInstance.functional["Team" .. (3 - scoringTeam) .. "GoalSensor"])
	rx.Observable.timer(4):subscribe(function ()
		sound:Stop()
	end)
end
local function declareWinner(soccerInstance, team)
	soccerInstance.state.activity.winningTeam.Value = team
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
local function destroyBall(soccerInstance)
	axisUtil.destroyChild(soccerInstance.functional, "Ball")
end
local function spawnBall(soccerInstance)
	-- Clear old
	local functional = soccerInstance.functional

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
	local score = tableau.valueObjectsToTable(soccerInstance.state.activity.score)
	scoreboardUtil.setScore(soccerInstance.Scoreboard, score)
end
local function updateScoreboardTime(soccerInstance, secondsRemaining)
	scoreboardUtil.setTime(soccerInstance.Scoreboard, secondsRemaining)
end
local function placePlayerOnPitch(soccerInstance, player)
	local functional = soccerInstance.functional
	local teamIndex = activityUtil.getPlayerTeamIndex(soccerInstance, player)
	local spawnPlane = functional["Team" .. teamIndex .. "SpawnPlane"]
	activityUtil.spawnPlayersInPlane({ player }, spawnPlane, functional.BallSpawn.Position)
end
local function placeAllPlayersOnPitch(soccerInstance)
	for i = 1, 2 do
		local players = soccerInstance.state.activity.roster[i]:GetChildren()
		for _, value in pairs(players) do
			placePlayerOnPitch(soccerInstance, value.Value)
		end
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
			return rx.Observable.from(instance.state.activity.score[teamIndex])
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

-- Play start stream (when roster collection is complete)
local playStartStream = sessionStartStream:flatMap(function (activityInstance)
	return rx.Observable.from(activityInstance.state.activity.isCollectingRoster.Changed)
		:filter(dart.bind(activityUtil.isInSession, activityInstance))
		:reject()
		:first()
		:map(dart.constant(activityInstance))
end)

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
-- Eject players that are already in the thing when it starts
sessionStartStream:subscribe(activityUtil.ejectPlayers)

-----------------------------------
-- Volley state subscriptions
-- START VOLLEY when play starts OR on plain goal delay finished
plainGoalStream
	:delay(3)
	:filter(activityUtil.isInPlay)
	:merge(playStartStream)
	:subscribe(startVolley)

-- STOP VOLLEY when any goal is scored OR session terminates
teamScoredStream
	:merge(sessionEndStream)
	:subscribe(stopVolley)

-----------------------------------
-- Ball subscriptions
-- Respawn ball when it escapes OR volley starts
ballEscapedStream:merge(volleyStartStream):subscribe(function (instance)
	destroyBall(instance)
	spawnBall(instance)
end)
sessionEndStream:subscribe(destroyBall)

-----------------------------------
-- Score manipulation subscriptions
-- Increase score when ball is in goal
local ballInGoalStream = volleyActivePulse
	:map(function (soccerInstance)
		return soccerInstance, getBallInGoalScoringTeam(soccerInstance)
	end)
	:filter(dart.select(2))
ballInGoalStream:subscribe(increaseScore)
ballInGoalStream:subscribe(fireCannonsForTeam)

-- Declare winner on winning goal
local winneringTeamStream = winningGoalStream
	:map(function (soccerInstance, teamIndex)
		return soccerInstance, soccerInstance.state.activity.sessionTeams[teamIndex].Value
	end)
winneringTeamStream:subscribe(declareWinner)

-----------------------------------
-- Scoreboard subscriptions
-- Set teams on match start
sessionStartStream:subscribe(updateScoreboardTeams)

-- Update scoreboard when score changes
baseScoreStream:map(dart.select(1)):subscribe(updateScoreboardScore)

-- Update scoreboard time when time changes
scheduleStreams.chunkTimeLeft
	:flatMap(function (t)
		return rx.Observable.from(genesUtil.getInstances(soccer))
			:map(dart.drag(t))
	end)
	-- :subscribe(updateScoreboardTime)

-----------------------------------
-- Player placement subscriptions
-- Place all on volley start
volleyStartStream:subscribe(placeAllPlayersOnPitch)

-- Place single when they enter the roster
activityUtil.getPlayerAddedToRosterStream(soccer):subscribe(placePlayerOnPitch)

-----------------------------------
-- Sound streams
volleyStartStream:subscribe(function (soccerInstance)
	soundUtil.playSound(env.res.audio.sounds.Whistle, soccerInstance:FindFirstChild("BallSpawn", true))
end)
