--
--	Jackson Munsell
--	11 Sep 2020
--	dodgeball.server.lua
--
--	Dodgeball server activity driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local schedule = env.src.schedule
local activities = env.src.activities

-- modules
local rx       = require(axis.lib.rx)
local dart     = require(axis.lib.dart)
local tableau  = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local activityUtil    = require(activities.util)
local scoreboardUtil  = require(genes.scoreboard.util)
local scheduleStreams = require(schedule.streams)
local dodgeballActivityConfig = require(activities.dodgeballActivity.config)

local DodgeballTool = env.res.activities.tools.DodgeballTool

-- Roster management
local function newEmptyRoster()
	return { {}, {} }
end
local function newShuffledRoster(allPlayers)
	-- Shuffle the players and then break them into 2 even teams
	local roster = newEmptyRoster()
	local shuffledPool = tableau.shuffle(allPlayers)
	for i, v in ipairs(shuffledPool) do
		table.insert(roster[math.ceil(i / (#shuffledPool / 2))], v)
	end
	return roster
end
local function flipTeam(team)
	return 3 - team
end

-- Ball management
local function playerHasBall(player)
	return player.Character and player.Character:FindFirstChild(DodgeballTool.Name)
end

-- Start session
local function startSession(dodgeball, cabinTeam)
	-- instances
	local functional = dodgeball.instance.functional

	-- Create session components
	local balls = {}
	for _ = 1, 5 do
		table.insert(balls, dodgeballBall.new(DodgeballTool, functional.balls))
	end
	
	-- Shuffle roster
	local function newRoster()
		return newShuffledRoster(cabinTeam:GetPlayers())
	end

	-- Create critical subjects
	local rosterSubject = rx.BehaviorSubject.new(newRoster())
	local matchStateSubject = rx.BehaviorSubject.new(true)

	-- Terminator and subscriptions
	local terminator = dodgeball.sessionStreams.stop
	local function subscribe(stream, f)
		stream:takeUntil(terminator):subscribe(f)
	end
	local function onTerminate(f)
		terminator:first():subscribe(f)
	end

	-- Ragdoll business
	local ragdolls = {}
	local function ragdollPlayer(player)
		env.net.ragdoll.Push:FireClient(player)
		table.insert(ragdolls, player.Character)
	end
	local function popRagdolls()
		for _, character in pairs(ragdolls) do
			local player = character and env.Players:GetPlayerFromCharacter(character)
			if player then
				env.net.ragdoll.Pop:Fire(player)
			end
		end
	end

	-- --------------------------------------------------------------------------
	-- Player management functions
	local function getPlayerTeam(player)
		local roster = rosterSubject:getValue()
		return table.find(roster[1], player) or table.find(roster[2], player)
	end
	local function isPlayerActive(player)
		return getPlayerTeam(player)
	end

	-- --------------------------------------------------------------------------
	-- Ball business

	-- streams
	local function getBallEventStream(streamName)
		return rx.Observable.from(balls)
			:flatMap(function (ball)
				return ball.streams[streamName]
					:map(dart.drag(ball))
			end)
	end
	local function partitionBallTouchedWithPlayer(streamName)
		return getBallEventStream(streamName)
			:map(function (hit, ball)
				return (hit.Parent and env.Players:GetPlayerFromCharacter(hit.Parent)), ball
			end)
			:partition()
	end
	local function constrainBall(ball)
		local part = ball:getPart()
		if not axisUtil.isPointInPartXZ(part.Position, functional.PitchBounds) then
			ball:spawnAtPart(functional.BallSpawns["2"])
		end
	end

	local hotBallTouchedPlayerStream, hotBallTouchedBrickStream = partitionBallTouchedWithPlayer("hotTouched")

	local coldBallTouchedEmptyPlayerStream = partitionBallTouchedWithPlayer("coldTouched")
		:filter(isPlayerActive)
		:reject(playerHasBall)

	-- Here a lame player means anyone that is not the thrower but doesn't get out when they touch the ball.
	-- 	This encompasses both players that are already out and players that aren't part of the match at all.
	local hotBallTouchedActiveOpponentStream, hotBallTouchedLamePlayerStream = hotBallTouchedPlayerStream
		:partition(function (player, ball)
			local team = getPlayerTeam(player)
			return team and (team ~= getPlayerTeam(ball.state.thrower:getValue()))
		end)

	local liveBallBrickedStream = hotBallTouchedBrickStream
		:merge(hotBallTouchedLamePlayerStream)
		:map(rx.util.omitFirst)

	local ballStream = rx.Observable.heartbeat()
		:flatMap(function ()
			return rx.Observable.from(balls)
		end)

	-- subscriptions
	subscribe(ballStream, constrainBall)
	subscribe(coldBallTouchedEmptyPlayerStream, function (player, ball)
		ball:equipPlayer(player)
	end)
	subscribe(liveBallBrickedStream, function (ball)
		ball:brick()
	end)

	-- --------------------------------------------------------------------------
	-- Roster/scoreboard work

	-- functions
	local cyclePlayerIndicators = dart.bind(activityUtil.cyclePlayerIndicators, dodgeball, dodgeballActivityConfig)
	local destroyPlayerIndicators = dart.bind(activityUtil.destroyPlayerIndicators)
	local function spawnRoster()
		-- Put each player's character somewhere random within their team's spawn plane
		local roster = rosterSubject:getValue()
		for i = 1, 2 do
			local plane = functional["Team" .. i .. "SpawnPlane"]
			local focus = functional.CourtCenter.Position
			for _, player in pairs(roster[i]) do
				local point = axisUtil.getRandomPointInPart(plane)
				if player.Character then
					player.Character:SetPrimaryPartCFrame(CFrame.new(point, focus))
				end
			end
		end
	end
	local function dropPlayer(player)
		-- Ragdoll and remove from roster
		ragdollPlayer(player)
		activityUtil.removePlayerFromRoster(rosterSubject, player)

		-- Strip balls from player
		for _, ball in pairs(balls) do
			ball:stripFromPlayer(player)
		end
	end

	-- streams
	local dropPlayerStream = hotBallTouchedActiveOpponentStream
		:merge(rx.Observable.from(env.Players.PlayerRemoving))
	local scoreStream = rosterSubject
		:map(function (roster)
			return { #roster[1], #roster[2] }
		end)

	-- subscriptions
	local function bindScoreboard(f)
		return dart.bind(f, dodgeball.instance.Scoreboard)
	end
	subscribe(dropPlayerStream, dropPlayer) -- Remove hit player from match
	subscribe(rosterSubject, cyclePlayerIndicators)
	subscribe(scoreStream, bindScoreboard(scoreboardUtil.setScore))
	subscribe(scheduleStreams.chunkTimeLeft, bindScoreboard(scoreboardUtil.setTime))

	-- --------------------------------------------------------------------------
	-- Match state management

	-- functions
	local function initMatch()
		popRagdolls()
		rosterSubject:push(newRoster())
		spawnRoster()
		for i, ball in ipairs(balls) do
			ball:spawnAtPart(functional.BallSpawns:FindFirstChild(i))
		end
	end
	local function pushMatchState(v)
		return function () matchStateSubject:push(v) end
	end

	-- streams
	local matchStartStream = matchStateSubject:filter()
	local matchResultStream = rosterSubject
		:flatMap(function (roster)
			return rx.Observable.range(1, 2)
				:map(dart.carry(roster))
		end)
		:map(function (roster, teamCheck)
			if #roster[teamCheck] == 0 then
				-- return flipTeam(teamCheck)
			end
		end)
		:filter(function (result)
			return result and matchStateSubject:getValue()
		end)
		:multicast(rx.BehaviorSubject.new())
		:filter()

	-- subscriptions
	subscribe(matchStartStream, initMatch)
	subscribe(matchResultStream, pushMatchState(false))
	subscribe(matchResultStream:delay(3), pushMatchState(true))

	-- --------------------------------------------------------------------------
	-- Cleanup on terminate

	-- functions
	local function destroyBalls()
		for _, ball in pairs(balls) do
			ball:destroy()
		end
	end
	
	-- subscriptions
	onTerminate(function ()
		destroyPlayerIndicators()
		destroyBalls()
		popRagdolls()
	end)
end

-- Create dodgeball
local function createDodgeball(activityInstance)
	-- Primary activity business
	local dodgeball = activityUtil.createActivityFromInstance(activityInstance, dodgeballActivityConfig)

	-- Configure scoreboard from teams
	-- 	NOTE: In the future this will need to be moved to session started
	scoreboardUtil.setAppearanceFromConfig(activityInstance.Scoreboard, dodgeballActivityConfig.teams)

	-- Connect to session started
	dodgeball.sessionStreams.start:subscribe(dart.bind(startSession, dodgeball))
end

-- Connect to all dodgeballs forever
rx.Observable.fromInstanceTag(dodgeballActivityConfig.instanceTag)
	:subscribe(createDodgeball)
