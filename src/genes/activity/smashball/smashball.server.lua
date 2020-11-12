--
--	Jackson Munsell
--	11 Nov 2020
--	smashball.server.lua
--
--	smashball activity gene server driver
--

-- env
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local activity = genes.activity
local smashball = activity.smashball
local ragdoll = env.src.ragdoll

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local collection = require(axis.lib.collection)
local axisUtil = require(axis.lib.axisUtil)
local genesUtil = require(genes.util)
local rolesUtil = require(env.src.roles.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Ball management
local function isBallInBounds(smashballInstance)
	local functional = smashballInstance.functional
	local ball = functional.balls:FindFirstChild("Ball")
	return ball and axisUtil.isPointInPartXZ(ball.Position, functional.PitchBounds)
end
local function spawnBall(smashballInstance)
	local functional = smashballInstance.functional
	local ball = smashballInstance.config.smashball.ball.Value:Clone()
	ball.Name = "Ball"
	ball.CFrame = functional.BallSpawn.CFrame
	ball.Velocity = Vector3.new()
	ball.Parent = functional.balls
end
local function destroyBall(smashballInstance)
	smashballInstance.functional.balls:ClearAllChildren()
end

-- Roster management
local function isRosterReady(smashballInstance)
	return smashballInstance.state.smashball.rosterReady.Value
end
local function resetRosterReady(smashballInstance)
	smashballInstance.state.smashball.rosterReady.Value = false
end
local function fillRoster(smashballInstance)
	local roster = smashballInstance.state.smashball.roster
	for i = 1, 2 do
		tableau.from(smashballInstance.state.activity.sessionTeams[i].Value:GetPlayers())
			:reject(rolesUtil.isPlayerCounselor)
			:foreach(dart.bind(collection.addValue, roster[i]))
	end
	smashballInstance.state.smashball.rosterReady.Value = true
end
local function dropPlayer(smashballInstance, player)
	-- Push ragdoll and remove from roster
	local state = smashballInstance.state.smashball
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
local function spawnPlayers(smashballInstance)
	local teams = smashballInstance.state.activity.sessionTeams
	local spawnRadius = smashballInstance.config.smashball.spawnRadius.Value
	local pitchCenter = smashballInstance.functional.ArenaCenter.Position
	local allPlayers = tableau.concat(teams[1].Value:GetPlayers(), teams[2].Value:GetPlayers())
	for i, player in pairs(allPlayers) do
		local spawnPosition = CFrame.new(pitchCenter) * CFrame.Angles(0, (i / #allPlayers) * math.pi * 2, 0)
		spawnPosition = (spawnPosition * CFrame.new(0, 0, spawnRadius)).p
		if player.Character then
			player.Character:SetPrimaryPartCFrame(CFrame.new(spawnPosition, pitchCenter))
		end
	end
end
local function declareWinner(smashballInstance, team)
	smashballInstance.state.activity.winningTeam.Value = team
end
local function restoreRagdolls(smashballInstance)
	local ragdolls = smashballInstance.state.smashball.ragdolls
	tableau.from(ragdolls:GetChildren()):foreach(function (value)
		local player = value.Value and Players:GetPlayerFromCharacter(value.Value)
		if player then
			ragdoll.net.Pop:FireClient(player)
		end
	end)
	collection.clear(ragdolls)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local smashballInstances = genesUtil.initGene(smashball)

-- Session state
local sessionStart, sessionEnd = genesUtil.crossObserveStateValue(smashball, activity, "inSession")
	:partition(dart.select(2))

-- Roster changed
local function getTeamRosterStream(index)
	return smashballInstances
		:flatMap(function (instance)
			return collection.observeChanged(instance.state.smashball.roster[index])
				:map(dart.carry(instance))
		end)
end
local baseRosterStream = getTeamRosterStream(1):merge(getTeamRosterStream(2))

-- Character died
local playerDied = axisUtil.getHumanoidDiedStream()
	:map(function (h)
		return Players:GetPlayerFromCharacter(h.Parent)
	end)
	:flatMap(function (p)
		return rx.Observable.from(genesUtil.getInstances(smashball))
			:map(dart.drag(p))
	end)

-- Ball touched character
local playerHitByBall = smashballInstances
	:flatMap(function (instance)
		return rx.Observable.from(instance.functional.balls.ChildAdded)
			:flatMap(function (ball)
				return rx.Observable.from(ball.Touched)
					:map(dart.carry(instance))
			end)
	end)
	:map(function (instance, hit)
		return instance, Players:GetPlayerFromCharacter(hit.Parent)
	end)
	:filter(dart.select(2))

-- Ball escaped
local ballEscaped = rx.Observable.heartbeat()
	:map(dart.bind(genesUtil.getInstances, smashball))
	:flatMap(rx.Observable.from)
	:reject(isBallInBounds)

---------------------------------------------------------------------------------------------------
-- Subscriptions
---------------------------------------------------------------------------------------------------

-- Fill roster on session start
sessionStart:subscribe(fillRoster)
sessionEnd:subscribe(resetRosterReady)

-- Spawn players on session start
sessionStart:subscribe(spawnPlayers)

-- Declare winner when a team has zero players
baseRosterStream
	:filter(isRosterReady)
	:map(function (instance)
		for i = 1, 2 do
			if #instance.state.smashball.roster[i]:GetChildren() == 0 then
				return instance, instance.state.activity.sessionTeams[3 - i].Value
			end
		end
	end)
	:filter()
	:subscribe(declareWinner)

-- Drop player when touched by a ball OR character reset
playerDied:merge(playerHitByBall):subscribe(dropPlayer)

-- Respawn ball on match start AND ball escaped
ballEscaped:merge(sessionStart):subscribe(function (instance)
	destroyBall(instance)
	spawnBall(instance)
end)
sessionEnd:subscribe(destroyBall)

-- Restore ragdolls on session end
sessionEnd:delay(2):subscribe(restoreRagdolls)
