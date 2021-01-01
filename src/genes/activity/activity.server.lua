--
--	Jackson Munsell
--	09 Nov 2020
--	activity.server.lua
--
--	activity gene server driver
--

-- env
local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local activity = genes.activity

-- modules
local fx = require(axis.lib.fx)
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local soundUtil = require(axis.lib.soundUtil)
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)
local pickupUtil = require(genes.pickup.util)
local patchUtil = require(genes.patch.util)
local activityUtil = require(activity.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Roster management
local function addPlayerToRoster(activityInstance, player)
	local teamIndex = activityUtil.getPlayerTeamIndex(activityInstance, player)
	local state = activityInstance.state.activity
	collection.addValue(state.roster[teamIndex], player)
	collection.addValue(state.fullRoster[teamIndex], player)
end

-- Set sprint particles to team color
local function setPlayerSprintEmitterTeam(player, team)
	local emitter = player.Character and player.Character:FindFirstChild("SprintEmitter")
	if emitter then
		emitter.state.teamLink.team.Value = team
	end
end
local function setPlayerSprintParticlesToTeamColor(player)
	setPlayerSprintEmitterTeam(player, player.Team)
end
local function clearPlayerSprintParticlesColor(player)
	setPlayerSprintEmitterTeam(player, nil)
end

-- Gear
local function givePlayerActivityGear(activityInstance, player)
	for _, value in pairs(activityInstance.config.activity.gear:GetChildren()) do
		local copy = value.Value:Clone()
		collection.addValue(activityInstance.state.activity.gear, copy)
		copy.Parent = ReplicatedStorage
		genesUtil.waitForGene(copy, genes.pickup)
		copy.state.pickup.activity.Value = activityInstance
		pickupUtil.stowObjectForPlayer(player, copy)
	end
end
local function stripPlayerActivityGear(activityInstance, player)
	local gear = activityInstance.state.activity.gear
	for _, entry in pairs(gear:GetChildren()) do
		if entry.Value and entry.Value:IsDescendantOf(game)
		and entry.Value.state.pickup.owner.Value == player then
			entry.Value:Destroy()
			entry:Destroy()
		end
	end
end

-- Start collecting roster
local function getRosterTimerLabels(activityInstance)
	local labels = {}
	for _, label in pairs(activityInstance.config.activity.pitch.Value:GetDescendants()) do
		if label.Name == "RosterTimerLabel" then
			table.insert(labels, label)
		end
	end
	if #labels == 0 then
		warn("No RosterTimerLabel instances found for " .. activityInstance:GetFullName())
	end
	return labels
end
local function setRosterTimersVisible(activityInstance, visible)
	local timerLabels = getRosterTimerLabels(activityInstance)
	for _, label in pairs(timerLabels) do
		label.Parent.Enabled = visible
	end
end
local function startCollectingRoster(activityInstance)
	-- Move all enrolled teams to session teams
	local state = activityInstance.state.activity
	for _, value in pairs(state.enrolledTeams:GetChildren()) do
		value.Parent = state.sessionTeams
	end

	-- Set state values to trigger any observers
	state.isCollectingRoster.Value = true
	state.inSession.Value = true

	-- Show countdown part
	local timerLabels = getRosterTimerLabels(activityInstance)
	local function setTimerText(t)
		for _, label in pairs(timerLabels) do
			label.Text = t
			label.Shadow.Text = t
		end
	end
	rx.Observable.heartbeat()
		:scan(function (t, dt)
			return t - dt
		end, activityInstance.config.activity.rosterCollectionTimer.Value)
		:map(math.floor)
		:takeUntil(rx.Observable.from(state.isCollectingRoster):reject())
		:subscribe(setTimerText)

	-- Fire analytics event
	local teamsData = {}
	for _, team in pairs(activityInstance.state.activity.sessionTeams:GetChildren()) do
		table.insert(teamsData, team.Value.Name)
	end
	AnalyticsService:FireEvent("activityStarted", {
		activityName = activityInstance.config.activity.analyticsName.Value,
		teams = teamsData,
	})
end

-- Start PLAY (called after roster collection is completed)
local function startPlay(activityInstance)
	-- Get state
	local state = activityInstance.state.activity
	local config = activityInstance.config.activity

	-- If we have players on both teams, then start a match
	local hasBoth = true
	for i = 1, config.teamCount.Value do
		local folder = state.roster[i]
		if #folder:GetChildren() < config.minPlayersPerTeam.Value then
			hasBoth = false
			break
		end
	end
	if not hasBoth then
		activityUtil.zeroJoinTerminate(activityInstance)
	end

	-- Either way, we are no longer collecting roster
	wait()
	state.isCollectingRoster.Value = false
end

-- Create trophy for activity instance and team, place it at the spawn
local function createTrophy(activityInstance, team)
	-- Create trophy
	local config = activityInstance.config.activity
	local pitch = config.pitch.Value
	local teamIndex = activityUtil.getTeamIndex(activityInstance, team)
	local teamSpawn = pitch.functional:FindFirstChild("Team" .. teamIndex .. "TrophySpawn")
	local trophySpawn = teamSpawn or pitch.functional.TrophySpawn
	local trophy = config.trophy.Value:Clone()
	trophy:SetPrimaryPartCFrame(trophySpawn.CFrame)
	trophy.Parent = workspace
	trophy.state.teamLink.team.Value = team

	-- Play sound inside the trophy
	soundUtil.playSound(env.res.audio.sounds.MatchWon, trophy)
end

-- Award patches
local function awardPatches(activityInstance, team)
	for _, entry in pairs(activityUtil.getTeamFullRoster(activityInstance, team):GetChildren()) do
		patchUtil.givePlayerPatch(entry.Value, activityInstance.config.activity.patch.Value:Clone())
	end
end

-- Render gates
local function setGatePartVisible(part, visible)
	part.CanCollide = visible
end
local function initGates(activityInstance)
	tableau.from(activityInstance.config.activity.pitch.Value:GetDescendants())
		:filter(function (m)
			return m.Name == "GateOpen" or m.Name == "GateClosed"
		end)
		:foreach(dart.bind(fx.new, "TransparencyEffect"))
end
local function renderGates(activityInstance)
	local inSession = activityInstance.state.activity.inSession.Value
	local function work(modelName, visible)
		local models = tableau.from(activityInstance.config.activity.pitch.Value:GetDescendants())
			:filter(dart.isNamed(modelName))
		models:foreach(function (m)
			m:WaitForChild("TransparencyEffect").Value = (visible and 0 or 1)
		end)
		models:flatMap(dart.getDescendants)
			:filter(dart.isa("BasePart"))
			:foreach(dart.follow(setGatePartVisible, visible))
	end
	work("GateOpen", not inSession)
	work("GateClosed", inSession)
end

-- Lock the pitch to only players in the roster
local function lockPitch(activityInstance)
	local pitch = activityInstance.config.activity.pitch.Value
	for _, player in pairs(Players:GetPlayers()) do
		local root = axisUtil.getPlayerHumanoidRootPart(player)
		if root then
			local inRoster = activityUtil.isPlayerInRoster(activityInstance, player)
			local inPitch = axisUtil.isPointInPartXZ(root.Position, pitch.functional.PitchBounds)
			if inRoster ~= inPitch then
				if inRoster then
					activityUtil.spawnPlayer(activityInstance, player)
				else
					activityUtil.ejectPlayerFromActivity(activityInstance, player)
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local activities = genesUtil.initGene(activity)

-- Set roster timer visible
genesUtil.observeStateValue(activity, "isCollectingRoster"):subscribe(setRosterTimersVisible)

-- Add and remove activity gear according to our presence on a roster
activityUtil.getPlayerAddedToRosterStream(genes.activity):subscribe(givePlayerActivityGear)
activityUtil.getPlayerRemovedFromRosterStream(genes.activity):subscribe(stripPlayerActivityGear)

-- Listen to enrolled list changed and begin activity when it's full
-- We have to spawn the subscription to this because it is subscribes to the collection's ChildRemoved event
-- 	and will create an infinite loop if single-threaded
local rosterFullStream = activities
	:flatMap(function (activityInstance)
		return rx.Observable.from(activityInstance.state.activity.roster:GetChildren())
			:flatMap(collection.observeChanged)
			:map(dart.constant(activityInstance))
	end)
	:filter(function (activityInstance)
		local config = activityInstance.config.activity
		local roster = activityInstance.state.activity.roster
		local maxPlayers = config.maxPlayersPerTeam.Value
		for i = 1, config.teamCount.Value do
			if #roster[i]:GetChildren() < maxPlayers then
				return false
			end
		end
		return true
	end)
local rosterCollectingStart = activities
	:flatMap(function (activityInstance)
		local enrolled = activityInstance.state.activity.enrolledTeams
		return collection.observeChanged(enrolled)
			:reject(dart.bind(activityUtil.isInSession, activityInstance))
			:map(function () return #enrolled:GetChildren() end)
			:filter(dart.equals(activityInstance.config.activity.teamCount.Value))
			:map(dart.constant(activityInstance))

			-- Temporary wait for open pitch. Needs improvement badly
			:map(function ()
				local config = activityInstance.config.activity
				if config.sharesPitch.Value then
					repeat wait() until not activityUtil.pitchHasActiveGame(config.pitch.Value)
				end
				return activityInstance
			end)
	end)
	:share()
rosterCollectingStart
	:map(dart.carry(startCollectingRoster))
	:map(dart.bind)
	:subscribe(spawn)

-- When a session starts, poll at 2hz to remove glitchers from inside and bring
-- 	back glitchers from outside
genesUtil.observeStateValue(activity, "inSession"):filter(dart.select(2)):subscribe(function (activityInstance)
	if not activityInstance.config.activity.lockPitch.Value then return end
	rx.Observable.interval(0.5)
		:takeUntil(rx.Observable.from(activityInstance.state.activity.inSession)
			:reject())
			-- :merge(rx.Observable.from(activityInstance.state.activity.winningTeam)))
		:subscribe(dart.bind(lockPitch, activityInstance))
end)

-- Start play when ALL teams are full OR the roster collection period is over
rosterCollectingStart
	:delay(function (activityInstance)
		return activityInstance.config.activity.rosterCollectionTimer.Value
	end)
	:merge(rosterFullStream)
	:filter(function (activityInstance)
		local state = activityInstance.state.activity
		return state.inSession.Value and state.isCollectingRoster.Value
	end)
	:subscribe(startPlay)

-- Add players to roster upon request
rx.Observable.from(activity.net.RosterJoinRequested)
	:filter(function (player, activityInstance)
		local state = activityInstance.state.activity
		return state.isCollectingRoster.Value and collection.getValue(state.sessionTeams, player.Team)
	end)
	:reject(activityUtil.isPlayerCompeting)
	:map(function (p, a) return a, p end)
	:subscribe(addPlayerToRoster)

-- Remove players from roster when they leave the game or die
local leaveRequested = rx.Observable.from(activity.net.LeaveActivityRequested)
axisUtil.getPlayerCharacterStream():flatMap(function (_, character)
	return rx.Observable.fromInstanceEvent(character:WaitForChild("Humanoid"), "Died")
end):merge(rx.Observable.from(Players.PlayerRemoving))
	:subscribe(activityUtil.removePlayerFromRosters)
leaveRequested:subscribe(function (player)
	local activityInstance = activityUtil.getPlayerActivity(player)
	if activityInstance then
		activityUtil.ejectPlayerFromActivity(activityInstance, player)
		activityUtil.removePlayerFromRosters(player)
	else
		warn("Player attempted to leave an activity but is not on any rosters")
	end
end)

-- Change color of sprint particles when they join a roster
activityUtil.getPlayerAddedToRosterStream(genes.activity):map(dart.select(2))
	:subscribe(setPlayerSprintParticlesToTeamColor)
activityUtil.getPlayerRemovedFromRosterStream(genes.activity):map(dart.select(2))
	:subscribe(clearPlayerSprintParticlesColor)

-- Stop session when a winner is declared from the inside
local winnerDeclared = genesUtil.observeStateValue(activity, "winningTeam")
	:filter(dart.select(2))

-- Create trophy when a winner is declared
-- winnerDeclared:subscribe(createTrophy)
winnerDeclared:subscribe(awardPatches)
winnerDeclared:map(dart.select(1)):delay(1.0):subscribe(activityUtil.stopSession)

-- Hard switch gates on activity session
activities:subscribe(initGates)
genesUtil.observeStateValue(activity, "inSession")
	:subscribe(renderGates)
