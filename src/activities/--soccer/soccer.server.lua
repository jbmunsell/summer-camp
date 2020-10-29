--
--	Jackson Munsell
--	06 Sep 2020
--	soccer.server.lua
--
--	Soccer activity driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local enum = env.src.enum
local objects = env.src.objects
local schedule = env.src.schedule
local activities = env.src.activities

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local activitiesUtil = require(activities.util)
local scoreboardUtil = require(objects.scoreboard.util)
local scheduleStreams = require(schedule.streams)
local InstanceTags = require(enum.InstanceTags)

-- instances
local soccerConfig = require(env.config.activities).soccer

-- Flip team
-- 	Given a team, this will return the other team (1 to 2, 2 to 1)
local function flipTeam(teamIndex)
	return 3 - teamIndex
end
local function newEmptyScore()
	return { 0, 0 }
end
local function getTeamGoal(activityInstance, teamIndex)
	return activityInstance.functional["Team" .. teamIndex .. "GoalSensor"]
end

-- Roster management
local function newEmptyRoster()
	return { {}, {} }
end
local function newShuffledRoster(playerPool)
	-- Shuffle the players and then break them into 2 even teams
	local roster = newEmptyRoster()
	local shuffledPool = tableau.shuffle(playerPool)
	for i, v in ipairs(shuffledPool) do
		table.insert(roster[math.ceil(i / (#shuffledPool / 2))], v)
	end
	return roster
end

-- Start session
local function startSession(soccer, cabinTeam)
	-- instances
	local scoreboard = soccer.instance.Scoreboard
	local functional = soccer.instance.functional

	-- Quick roster
	local function newRoster()
		return newShuffledRoster(cabinTeam:GetPlayers())
	end

	-- Important behavior subjects
	local matchStateSubject = rx.BehaviorSubject.new(true)
	local volleyStateSubject = rx.BehaviorSubject.new()
	local scoreSubject = rx.BehaviorSubject.new()
	local rosterSubject = rx.BehaviorSubject.new(newRoster())

	-- Shared stream
	local matchStartStream = matchStateSubject:filter()

	-- Terminator and subscribe helper function
	local terminator = soccer.sessionStreams.stop:first()
	local function subscribe(stream, f)
		stream:takeUntil(terminator):subscribe(f)
	end
	local function onTerminate(f)
		terminator:first():subscribe(f)
	end

	-- --------------------------------------------------------------------------
	-- Ball business

	-- functions
	local function clearBalls()
		functional.balls:ClearAllChildren()
	end
	local function spawnBall()
		local ball = env.res.activities.models.SoccerBall:Clone()
		ball.Velocity = Vector3.new(0, 0, 0)
		ball.CFrame = functional.BallSpawn.CFrame
		ball.Parent = functional.balls
	end
	local function respawnBall(ball)
		ball:Destroy()
		spawnBall(soccer.instance)
	end
	local function isBallInGoal(defendingTeam, ball)
		return axisUtil.isPointInPart(ball.Position, getTeamGoal(soccer.instance, defendingTeam))
	end
	local function isBallInBounds(ball)
		return axisUtil.isPointInPartXZ(ball.Position, functional.PitchBounds)
	end

	-- streams
	local ballStream = rx.Observable.heartbeat()
		:flatMap(function ()
			return rx.Observable.from(soccer.instance.functional.balls:GetChildren())
		end)
	local ballInGoalStream = ballStream
		:flatMap(function (ball)
			return rx.Observable.range(1, 2)
				:map(dart.drag(ball))
		end)
		:filter(isBallInGoal)
		:map(flipTeam)
	local ballLeftBoundsStream = ballStream
		:reject(isBallInBounds)

	-- subscriptions
	subscribe(ballLeftBoundsStream, respawnBall)

	-- --------------------------------------------------------------------------
	-- Roster management

	-- functions
	local removeFromRoster = dart.bind(activitiesUtil.removePlayerFromRoster, rosterSubject)
	local cyclePlayerIndicators = dart.bind(activitiesUtil.cyclePlayerIndicators, soccer, soccerConfig)
	local destroyPlayerIndicators = dart.bind(activitiesUtil.destroyPlayerIndicators, soccer)

	-- subscriptions
	subscribe(rx.Observable.from(env.Players.PlayerRemoving), removeFromRoster)
	subscribe(rosterSubject, cyclePlayerIndicators)

	-- --------------------------------------------------------------------------
	-- Score management

	-- functions
	local function resetScore()
		print("resetting score")
		scoreSubject:push(newEmptyScore())
	end
	local function increaseTeamScore(team)
		print("increasing score")
		local score = tableau.duplicate(scoreSubject:getValue())
		score[team] = score[team] + 1
		scoreSubject:push(score, team)
	end
	local function echoWin(winningTeam)
		print(string.format("Team %d wins!", winningTeam))
	end
	local function echoPlainGoal(scoringTeam)
		print(string.format("Team %d scores!", scoringTeam))
	end

	scoreSubject:subscribe(print)

	-- streams
	local teamScoredStream = ballInGoalStream
		:filter(function (scoringTeam)
			return scoringTeam and volleyStateSubject:getValue()
		end)
		:share()
	local winStream, plainGoalStream = scoreSubject
		:skip(1) -- Skip the initial value to avoid these events firing on session start
		:filter(function (score, team) -- This filters out score reset events
			return score and team
		end)
		:partition(function (score, team)
			return score[team] >= soccerConfig.GoalsToWin
		end)
	winStream = winStream:map(dart.omitFirst):share()
	plainGoalStream = plainGoalStream:map(dart.omitFirst)

	-- subscriptions
	subscribe(matchStartStream, resetScore)
	subscribe(teamScoredStream, increaseTeamScore)
	subscribe(scoreSubject, dart.bind(scoreboardUtil.setScore, scoreboard))
	subscribe(scheduleStreams.chunkTimeLeft, dart.bind(scoreboardUtil.setTime, scoreboard))
	subscribe(winStream, echoWin)
	subscribe(plainGoalStream, echoPlainGoal)

	-- --------------------------------------------------------------------------
	-- Volley and match state management

	-- functions
	local function spawnRoster()
		-- Put each player's character somewhere random within their team's spawn plane
		local roster = rosterSubject:getValue()
		for i = 1, 2 do
			local plane = functional["Team" .. i .. "SpawnPlane"]
			local focus = functional.BallSpawn.Position
			for _, player in pairs(roster[i]) do
				local point = axisUtil.getRandomPointInPart(plane)
				if player.Character then
					player.Character:SetPrimaryPartCFrame(CFrame.new(point, focus))
				end
			end
		end
	end
	local function initMatch()
		rosterSubject:push(newRoster())
		volleyStateSubject:push(true)
	end
	local function initVolley()
		spawnRoster()
		clearBalls()
		spawnBall()
	end

	-- streams
	local volleyStartStream = volleyStateSubject:filter()

	-- subscriptions
	local function cycleStateAfterStream(stream, state)
		subscribe(stream, function () state:push(false) end)
		subscribe(stream:delay(3), function () state:push(true) end)
	end
	subscribe(volleyStartStream, initVolley)
	subscribe(matchStartStream, initMatch)
	cycleStateAfterStream(teamScoredStream, volleyStateSubject)
	cycleStateAfterStream(winStream, matchStateSubject)

	-- --------------------------------------------------------------------------
	-- Session terminated cleanup functions

	-- Mop it baby
	onTerminate(destroyPlayerIndicators)
	onTerminate(clearBalls)
end

-- Create soccer
local function createSoccer(activityInstance)
	-- Create streams and engagement portal
	local soccer = activitiesUtil.createActivityFromInstance(activityInstance, soccerConfig)

	-- Configure scoreboard from teams
	-- 	NOTE: In the future this will need to be moved to session started
	scoreboardUtil.setAppearanceFromConfig(activityInstance.Scoreboard, soccerConfig.teams)

	-- Connect to session started
	soccer.sessionStreams.start:subscribe(dart.bind(startSession, soccer))
end

-- Connect to all soccer instances
rx.Observable.fromInstanceTag(InstanceTags.Activities.Soccer)
	:subscribe(createSoccer)
