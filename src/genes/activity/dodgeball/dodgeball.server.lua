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
	-- local spawnIndex = getBalls(dodgeballInstance):size() + 1
	local spawnIndex = #dodgeballInstance.functional.balls:GetChildren() + 1
	local ball = dodgeballInstance.config.dodgeball.ball.Value:Clone()
	ball.CFrame = CFrame.new(dodgeballInstance.functional.BallSpawns[spawnIndex].Position)
	ball.Parent = dodgeballInstance.functional.balls
	genesUtil.addGeneTag(ball, dodgeballBall)
end

-- Roster manipulation
local function dropPlayer(dodgeballInstance, player)
	-- Push ragdoll and remove from roster
	local state = dodgeballInstance.state.activity
	local value
	for i = 1, 2 do
		value = collection.getValue(state.roster[i], player)
		if value then break end
	end
	if not value then return end

	if player.Character then
		print("Attempting to strip balls")
		for _, ball in pairs(dodgeballInstance.functional.balls:GetChildren()) do
			print("checking ball")
			if ball.state.pickup.holder.Value == player.Character then
				print("Character is holding ball; stripping")
				pickupUtil.stripObject(ball)
				print("stripped")
			end
		end
		soundUtil.playSound(env.res.audio.sounds.Whistle, player.Character.PrimaryPart)
	end
	value:Destroy()
	ragdoll.net.Push:FireClient(player)
	collection.addValue(dodgeballInstance.state.dodgeball.ragdolls, player.Character)
end
local function spawnPlayer(dodgeballInstance, player)
	local functional = dodgeballInstance.functional
	local teamIndex = activityUtil.getPlayerTeamIndex(dodgeballInstance, player)
	local spawnPlane = functional["Team" .. teamIndex .. "SpawnPlane"]
	activityUtil.spawnPlayersInPlane({ player }, spawnPlane, functional.CourtCenter.Position)
end
local function spawnAllPlayers(dodgeballInstance)
	for i = 1, 2 do
		local players = dodgeballInstance.state.activity.roster[i]:GetChildren()
		for _, value in pairs(players) do
			spawnPlayer(dodgeballInstance, value.Value)
		end
	end
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
local dodgeballInstances = genesUtil.initGene(dodgeball)

-- Session streams
local sessionStart, sessionEnd = genesUtil.crossObserveStateValue(dodgeball, activity, "inSession")
	:partition(dart.select(2))

-- Play start stream (when roster collection is complete)
local playStartStream = sessionStart:flatMap(function (activityInstance)
	return rx.Observable.from(activityInstance.state.activity.isCollectingRoster.Changed)
		:filter(dart.bind(activityUtil.isInSession, activityInstance))
		:reject()
		:first()
		:map(dart.constant(activityInstance))
end)

-- Roster changed
local playerRemovedFromRoster = activityUtil.getPlayerRemovedFromRosterStream(dodgeball)

-- Score changed
local scoreChangedStream = dodgeballInstances:flatMap(function (dodgeballInstance)
	local score = dodgeballInstance.state.activity.score
	return rx.Observable.from(score:GetChildren())
		:flatMap(rx.Observable.from)
		:map(dart.constant(dodgeballInstance))
end)

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
		local player
		for _, p in pairs(Players:GetPlayers()) do
			if p.Character and hit:IsDescendantOf(p.Character) then
				player = p
				break
			end
		end
		if not player then
			for _, p in pairs(genesUtil.getInstances(genes.player.characterBackpack):raw()) do
				local backpack = p.state.characterBackpack.instance.Value
				if backpack and hit:IsDescendantOf(backpack) then
					player = p
					break
				end
			end
		end
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
playStartStream:subscribe(spawnAllPlayers)
activityUtil.getPlayerAddedToRosterStream(dodgeball):subscribe(spawnPlayer)

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
