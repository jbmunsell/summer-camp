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
local ragdoll = env.src.character.ragdoll

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local soundUtil = require(axis.lib.soundUtil)
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)
local activityUtil = require(activity.util)
local scoreboardUtil = require(genes.scoreboard.util)
local scheduleStreams = require(env.src.schedule.streams)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Ball manipulation
local function getBalls(dodgeballInstance)
	return dodgeballInstance.functional.balls:GetChildren()
end
local function isBallInBounds(dodgeballInstance, ball)
	return axisUtil.isPointInPartXZ(ball.Position, dodgeballInstance.functional.PitchBounds)
end
local function destroyBall(_, ball)
	ball:Destroy()
end
local function spawnBall(dodgeballInstance)
	local spawnIndex = #dodgeballInstance.functional.balls:GetChildren() + 1
	local ball = dodgeballInstance.config.dodgeball.ball.Value:Clone()
	ball.CFrame = CFrame.new(dodgeballInstance.functional.BallSpawns[spawnIndex].Position)
	ball.Parent = dodgeballInstance.functional.balls
	genesUtil.addGeneTag(ball, dodgeballBall)
end

-- Roster manipulation
local function dropPlayer(dodgeballInstance, player)
	-- Push ragdoll and strip balls
	if not activityUtil.isPlayerInRoster(dodgeballInstance, player) then return end

	if player.Character then
		for _, ball in pairs(dodgeballInstance.functional.balls:GetChildren()) do
			if ball.state.pickup.holder.Value == player.Character then
				pickupUtil.stripObject(ball)
			end
		end
		soundUtil.playSound(env.res.audio.sounds.Whistle, player.Character.PrimaryPart)
		collection.addValue(dodgeballInstance.state.dodgeball.ragdolls, player.Character)
	end
	ragdoll.net.Push:FireClient(player)
end
local function releasePlayerRagdoll(dodgeballInstance, player)
	ragdoll.net.Pop:FireClient(player)
	collection.removeValue(dodgeballInstance.state.dodgeball.ragdolls, player.Character)
end
local function restoreRagdolls(dodgeballInstance)
	local ragdolls = dodgeballInstance.state.dodgeball.ragdolls
	tableau.from(ragdolls:GetChildren()):foreach(function (value)
		local player = value.Value and Players:GetPlayerFromCharacter(value.Value)
		if player then
			releasePlayerRagdoll(dodgeballInstance, player)
		end
	end)
	collection.clear(ragdolls)
end

-- Scoreboard 
local function updateScoreboardTeams(dodgeballInstance)
	scoreboardUtil.setTeams(dodgeballInstance.Scoreboard, dodgeballInstance.state.activity.sessionTeams)
end
local function updateScore(dodgeballInstance)
	local state = dodgeballInstance.state.activity
	for i = 1, 2 do
		state.score[i].Value = #state.roster[i]:GetChildren()
	end
end
local function updateScoreboardScore(dodgeballInstance)
	local score = {}
	for i = 1, 2 do
		score[i] = #dodgeballInstance.state.activity.roster[i]:GetChildren()
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
genesUtil.initGene(dodgeball)

-- Session streams
local sessionStart, sessionEnd = activityUtil.getSessionStateStreams(dodgeball)
local playStartStream = activityUtil.getPlayStartStream(dodgeball)
local playerRemovedFromRoster = activityUtil.getPlayerRemovedFromRosterStream(dodgeball)
local scoreChangedStream = activityUtil.getScoreChangedStream(dodgeball)

-- Character died
local playerLeft = rx.Observable.from(Players.PlayerRemoving)
local playerDied = axisUtil.getHumanoidDiedStream()
	:map(function (h)
		return Players:GetPlayerFromCharacter(h.Parent)
	end)

-- Ball touched character
local playerHitByBall = genesUtil.getInstanceStream(dodgeballBall)
	:flatMap(function (ball)
		return rx.Observable.from(ball.interface.dodgeballBall.TouchedNonThrowerPart)
			:map(dart.drag(ball))
	end)
	:map(function (hit, ball)
		local player = axisUtil.getPlayerFromCharacterDescendant(hit)
		if not player then
			for _, v in pairs(genesUtil.getInstances(genes.pickup):raw()) do
				if (hit == v or hit:IsDescendantOf(v)) then
					local p = Players:GetPlayerFromCharacter(v.state.pickup.holder.Value)
					if p then
						player = p
						break
					end
				end
			end
		end
		return player, ball
	end)
	:filter(dart.select(1))
	:map(function (player, ball)
		local instance = genesUtil.getInstances(dodgeball):first(function (instance)
			return ball:IsDescendantOf(instance) and instance.state.activity.inSession.Value
		end)
		if instance then
			return instance, player
		end
	end)
	:filter()
	:share()

---------------------------------------------------------------------------------------------------
-- Subscriptions
---------------------------------------------------------------------------------------------------

-- Spawn players on session start
sessionStart:subscribe(activityUtil.ejectPlayers)
playStartStream:subscribe(activityUtil.spawnAllPlayers)
activityUtil.getPlayerAddedToRosterStream(dodgeball):subscribe(activityUtil.spawnPlayer)

-- Get player out when they are touched by a hot ball OR their character dies
playerDied
	:merge(playerLeft)
	:flatMap(function (p)
		return rx.Observable.from(genesUtil.getInstances(dodgeball))
			:map(dart.drag(p))
	end)
	:merge(playerHitByBall)
	:filter(activityUtil.isInSession)
	:subscribe(dropPlayer)

-- Teleport them outside the court after 2 seconds if they're still there
playerHitByBall
	:map(function (di, p) return di, p.Character end)
	:delay(2)
	:subscribe(function (dodgeballInstance, character)
		local player = Players:GetPlayerFromCharacter(character)
		if character and character:IsDescendantOf(workspace) and player then
			releasePlayerRagdoll(dodgeballInstance, player)
			activityUtil.ejectPlayerFromActivity(dodgeballInstance, player)
			activityUtil.removePlayerFromRosters(player)
		end
	end)

-- Update the scoreboard teams when the session starts, and update the score when roster changes
sessionStart:subscribe(updateScoreboardTeams)
playerRemovedFromRoster:merge(activityUtil.getPlayerAddedToRosterStream(dodgeball))
	:subscribe(updateScore)
scheduleStreams.chunkTimeLeft
	:flatMap(function (t)
		return rx.Observable.from(genesUtil.getInstances(dodgeball))
			:map(dart.drag(t))
	end)
	-- :subscribe(updateScoreboardTime)

-- Update scoreboard when score changes
scoreChangedStream:subscribe(updateScoreboardScore)

-- Declare a winner when one team has zero players
activityUtil.getSingleTeamLeftStream(dodgeball):subscribe(activityUtil.declareWinner)

-- Destroy ball when it leaves
sessionEnd
	:delay(3)
	:pipe(dragBalls)
	:subscribe(destroyBall)

-- Spawn five balls on session start
playStartStream:flatMap(function (instance)
	return rx.Observable.range(1, 5)
		:map(dart.constant(instance))
end):subscribe(spawnBall)

-- When ball escapes, destroy and spawn
-- Ball escaped
rx.Observable.heartbeat():subscribe(function ()
	for _, dodgeballInstance in pairs(genesUtil.getInstances(dodgeball):raw()) do
		if activityUtil.isInPlay(dodgeballInstance) then
			for _, ball in pairs(getBalls(dodgeballInstance)) do
				if not isBallInBounds(dodgeballInstance, ball) then
					destroyBall(dodgeballInstance, ball)
					spawnBall(dodgeballInstance)
				end
			end
		end
	end
end)

-- Restore ragdolls on session end
sessionEnd:delay(2):subscribe(restoreRagdolls)
