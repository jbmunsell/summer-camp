--
--	Jackson Munsell
--	08 Sep 2020
--	smashball.server.lua
--
--	Smashball server activity driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local enum = env.src.enum
local activities = env.src.activities

-- modules
local rx       = require(axis.lib.rx)
local dart     = require(axis.lib.dart)
local tableau  = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local activitiesUtil = require(activities.util)
local InstanceTags   = require(enum.InstanceTags)

-- constants
local PlayerSpawnRadius = 25

-- instances
local smashballConfig = require(env.config.activities).smashball

-- enums
local MatchResult = tableau.enumerate({
	"DodgerWins",
	"NoSmashers",
})

-- Roster factories
local function newEmptyRoster()
	return { dodgers = {}, smashers = {} }
end
local function newFullRoster(allPlayers)
	local roster = newEmptyRoster()
	for _, player in ipairs(allPlayers) do
		table.insert(player.state.isCabinLeader.Value and roster.smashers or roster.dodgers, player)
	end
	return roster
	-- local p = env.Players:GetPlayers()[1]
	-- return { dodgers = { p, p, p }, smashers = { p, p, p } }
end

-- Session start
-- 	Binds up all the nice streams to neatly take until the session is terminated
local function startSession(smashball, cabinTeam)
	-- instances
	local functional = smashball.instance.functional

	-- New roster from cabin team
	local function newRoster()
		return newFullRoster(cabinTeam:GetPlayers())
	end

	-- Important behavior subjects
	local rosterSubject = rx.BehaviorSubject.new(newRoster())
	local matchStateSubject = rx.BehaviorSubject.new(true)

	-- Terminator and subscribe helper function
	local terminator = smashball.sessionStreams.stop
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
	-- Ball business

	-- functions
	local function clearBalls()
		functional.balls:ClearAllChildren()
	end
	local function spawnBall()
		local ball = env.res.activities.models.Smashball:Clone()
		ball.Velocity = Vector3.new(0, 0, 0)
		ball.CFrame = functional.BallSpawn.CFrame
		ball.Parent = functional.balls
	end
	local function respawnBall(ball)
		ball:Destroy()
		spawnBall(smashball.instance)
	end
	local function isBallInBounds(ball)
		return axisUtil.isPointInPartXZ(ball.Position, functional.PitchBounds)
	end

	-- streams
	local ballAddedStream = rx.Observable.from(functional.balls.ChildAdded)
	local ballTouchedPlayerStream = ballAddedStream
		:flatMap(function (ball)
			return rx.Observable.from(ball.Touched)
		end)
		:map(dart.getPlayerFromCharacterChild)
		:filter() -- Get out nil values
	local ballLeftBoundsStream = rx.Observable.heartbeat()
		:flatMap(function ()
			return rx.Observable.from(functional.balls:GetChildren())
		end)
		:reject(isBallInBounds)

	-- subscriptions
	subscribe(ballLeftBoundsStream, respawnBall)

	-- --------------------------------------------------------------------------
	-- Roster manipulation

	-- functions
	local function isDodger(player)
		return table.find(rosterSubject:getValue().dodgers, player)
	end
	local function spawnRoster()
		local roster = rosterSubject:getValue()
		local pitchCenter = functional.ArenaCenter.Position
		local allPlayers = tableau.concat(roster.dodgers, roster.smashers)
		for i, player in ipairs(allPlayers) do
			local spawnPosition = CFrame.new(pitchCenter) * CFrame.Angles(0, (i / #allPlayers) * math.pi * 2, 0)
			spawnPosition = (spawnPosition * CFrame.new(0, 0, PlayerSpawnRadius)).p
			if player.Character then
				player.Character:SetPrimaryPartCFrame(CFrame.new(spawnPosition, pitchCenter))
			end
		end
	end
	local function dropPlayer(player)
		ragdollPlayer(player)
		activitiesUtil.removePlayerFromRoster(rosterSubject, player)
	end
	local cyclePlayerIndicators = dart.bind(activitiesUtil.cyclePlayerIndicators, smashball, smashballConfig)
	local destroyPlayerIndicators = dart.bind(activitiesUtil.destroyPlayerIndicators, smashball)

	-- streams
	local dropPlayerStream = ballTouchedPlayerStream
		:filter(isDodger)
		:merge(rx.Observable.from(env.Players.PlayerRemoving))

	-- subscriptions
	subscribe(dropPlayerStream, dropPlayer)
	subscribe(rosterSubject, cyclePlayerIndicators)

	-- --------------------------------------------------------------------------
	-- Match state

	-- functions
	local function initMatch()
		popRagdolls()
		rosterSubject:push(newRoster())
		spawnRoster()
		clearBalls()
		spawnBall()
	end
	local function pushMatchState(v)
		return function () matchStateSubject:push(v) end
	end

	-- streams
	local matchStartStream = matchStateSubject:filter()
	local matchResultStream = rosterSubject
		:map(function (roster)
			if #roster.dodgers <= 1 then
				return { MatchResult.DodgerWins, roster.dodgers[1] }
			elseif #roster.smashers == 0 then
				return { MatchResult.NoSmashers }
			end
		end)
		:filter(function (result)
			return result and matchStateSubject:getValue()
		end)
		:multicast(rx.BehaviorSubject.new())

	-- subscriptions
	-- NOTE: putting result subscriptions after init subscription means that there is not an
	-- 	initial result check when the first match begins
	subscribe(matchStartStream, initMatch)
	subscribe(matchResultStream, pushMatchState(false))
	subscribe(matchResultStream:delay(3), pushMatchState(true))

	-- --------------------------------------------------------------------------
	-- Session terminated subscriptions

	-- Clear balls and destroy indicators
	onTerminate(clearBalls)
	onTerminate(destroyPlayerIndicators)
	onTerminate(popRagdolls)
end

-- Creation of smashball instances
local function createSmashball(activityInstance)
	-- Create streams and engagement portal
	local smashball = activitiesUtil.createActivityFromInstance(activityInstance, smashballConfig)

	-- Connect to session started
	smashball.sessionStreams.start:subscribe(dart.bind(startSession, smashball))
end

-- Connect to all smashball instances forever
rx.Observable.fromInstanceTag(InstanceTags.Activities.Smashball)
	:subscribe(createSmashball)
