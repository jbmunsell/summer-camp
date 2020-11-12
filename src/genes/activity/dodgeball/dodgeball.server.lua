--
--	Jackson Munsell
--	11 Nov 2020
--	dodgeball.server.lua
--
--	dodgeball activity gene server driver
--

-- env
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local activity = genes.activity
local dodgeball = activity.dodgeball
local dodgeballBall = genes.dodgeballBall
local ragdoll = env.src.ragdoll

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)
local activityUtil = require(activity.util)
local scoreboardUtil = require(genes.scoreboard.util)
local scheduleStreams = require(env.src.schedule.streams)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Ball manipulation
local function getBalls(dodgeballInstance)
	return genesUtil.getInstances(dodgeballBall)
		:filter(dart.isDescendantOf(dodgeballInstance))
end
local function isBallInBounds(dodgeballInstance, ball)
	return axisUtil.isPointInPartXZ(ball.Position, dodgeballInstance.functional.PitchBounds)
end
local function destroyBall(_, ball)
	ball:Destroy()
end
local function spawnBall(dodgeballInstance)
	local spawnIndex = getBalls(dodgeballInstance):size() + 1
	local ball = dodgeballInstance.config.dodgeball.ball.Value:Clone()
	ball.CFrame = CFrame.new(dodgeballInstance.functional.BallSpawns[spawnIndex].Position)
	ball.Parent = dodgeballInstance.functional.balls
	genesUtil.addGene(ball, dodgeballBall)
end

-- Roster manipulation
local function isRosterReady(dodgeballInstance)
	return dodgeballInstance.state.dodgeball.rosterReady.Value
end
local function resetRosterReady(dodgeballInstance)
	dodgeballInstance.state.dodgeball.rosterReady.Value = false
end
local function fillRoster(dodgeballInstance)
	local roster = dodgeballInstance.state.dodgeball.roster
	for i = 1, 2 do
		tableau.from(dodgeballInstance.state.activity.sessionTeams[i].Value:GetPlayers())
			:foreach(dart.bind(collection.addValue, roster[i]))
	end
	dodgeballInstance.state.dodgeball.rosterReady.Value = true
end
local function dropPlayer(dodgeballInstance, player)
	-- Push ragdoll and remove from roster
	local state = dodgeballInstance.state.dodgeball
	local value
	for i = 1, 2 do
		value = collection.getValue(state.roster[i], player)
		if value then break end
	end
	if not value then return end

	value:Destroy()
	ragdoll.net.Push:FireClient(player)
	collection.addValue(state.ragdolls, player.Character)
end
local function spawnPlayers(dodgeballInstance)
	local functional = dodgeballInstance.functional
	for i = 1, 2 do
		local spawnPlane = functional["Team" .. i .. "SpawnPlane"]
		local players = dodgeballInstance.state.activity.sessionTeams[i].Value:GetPlayers()
		activityUtil.spawnPlayersInPlane(players, spawnPlane, functional.CourtCenter.Position)
	end
end
local function declareWinner(dodgeballInstance, team)
	dodgeballInstance.state.activity.winningTeam.Value = team
end
local function restoreRagdolls(dodgeballInstance)
	local ragdolls = dodgeballInstance.state.dodgeball.ragdolls
	tableau.from(ragdolls:GetChildren()):foreach(function (value)
		local player = value.Value and Players:GetPlayerFromCharacter(value.Value)
		if player then
			ragdoll.net.Pop:FireClient(player)
		end
	end)
	collection.clear(ragdolls)
end

-- Scoreboard 
local function updateScoreboardTeams(dodgeballInstance)
	scoreboardUtil.setTeams(dodgeballInstance.Scoreboard, dodgeballInstance.state.activity.sessionTeams)
end
local function updateScoreboardScore(dodgeballInstance)
	local score = {}
	for i = 1, 2 do
		score[i] = #dodgeballInstance.state.dodgeball.roster[i]:GetChildren()
	end
	scoreboardUtil.setScore(dodgeballInstance.Scoreboard, score)
end
local function updateScoreboardTime(soccerInstance, secondsRemaining)
	scoreboardUtil.setTime(soccerInstance.Scoreboard, secondsRemaining)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- Drag balls operator
local function dragBalls(observable)
	return observable:flatMap(function (instance)
		return rx.Observable.from(getBalls(instance))
			:map(dart.carry(instance))
	end)
end

-- init
local dodgeballInstances = genesUtil.initGene(dodgeball)

-- Session streams
local sessionStart, sessionEnd = genesUtil.crossObserveStateValue(dodgeball, activity, "inSession")
	:partition(dart.select(2))

-- Roster changed
local function getTeamRosterStream(index)
	return dodgeballInstances
		:flatMap(function (instance)
			return collection.observeChanged(instance.state.dodgeball.roster[index])
				:map(dart.carry(instance))
		end)
end
local baseRosterStream = getTeamRosterStream(1):merge(getTeamRosterStream(2))

-- Character died
local playerDied = axisUtil.getHumanoidDiedStream()
	:map(function (h)
		return Players:GetPlayerFromCharacter(h.Parent)
	end)

-- Ball touched character
local playerHitByBall = genesUtil.getInstanceStream(dodgeballBall)
	:flatMap(function (ball)
		return rx.Observable.from(ball.interface.dodgeballBall.TouchedNonThrowerPart)
			:tap(print)
			:map(dart.drag(ball))
	end)
	:map(function (hit, ball)
		return Players:GetPlayerFromCharacter(hit.Parent), ball
	end)
	:filter(dart.select(1))
	:map(function (player, ball)
		local instance = genesUtil.getInstances(dodgeball):first(function (instance)
			return ball:IsDescendantOf(instance)
		end)
		if instance then
			return instance, player
		end
	end)

-- Ball escaped
local ballEscaped = rx.Observable.heartbeat()
	:map(dart.bind(genesUtil.getInstances, dodgeball))
	:flatMap(rx.Observable.from)
	:pipe(dragBalls)
	:reject(isBallInBounds)

---------------------------------------------------------------------------------------------------
-- Subscriptions
---------------------------------------------------------------------------------------------------

-- Fill roster on session start
sessionStart:subscribe(fillRoster)
sessionEnd:subscribe(resetRosterReady)

-- Spawn players on session start
sessionStart:subscribe(spawnPlayers)

-- Get player out when they are touched by a hot ball OR their character dies
playerDied
	:flatMap(function (p)
		return rx.Observable.from(genesUtil.getInstances(dodgeball))
			:map(dart.drag(p))
	end)
	:merge(playerHitByBall)
	:subscribe(dropPlayer)

-- Update the scoreboard teams when the session starts, and update the score when roster changes
sessionStart:subscribe(updateScoreboardTeams)
baseRosterStream:subscribe(updateScoreboardScore)
scheduleStreams.chunkTimeLeft
	:filter(activityUtil.isActivityChunk)
	:flatMap(function (t)
		return rx.Observable.from(genesUtil.getInstances(dodgeball))
			:map(dart.drag(t))
	end)
	:subscribe(updateScoreboardTime)

-- Declare a winner when one team has zero players
baseRosterStream
	:filter(isRosterReady)
	:map(function (instance)
		for i = 1, 2 do
			if #instance.state.dodgeball.roster[i]:GetChildren() == 0 then
				return instance, instance.state.activity.sessionTeams[3 - i].Value
			end
		end
	end)
	:filter()
	:subscribe(declareWinner)

-- Destroy ball when it leaves
sessionEnd
	:pipe(dragBalls)
	:subscribe(destroyBall)

-- Spawn five balls on session start
sessionStart
	:flatMap(function (instance)
		return rx.Observable.range(1, 5)
			:map(dart.constant(instance))
	end)
	:subscribe(spawnBall)

-- When ball escapes, destroy and spawn
ballEscaped:subscribe(function (instance, ball)
	destroyBall(instance, ball)
	spawnBall(instance)
end)

-- Restore ragdolls on session end
sessionEnd:delay(2):subscribe(restoreRagdolls)