--
--	Jackson Munsell
--	09 Nov 2020
--	activity.server.lua
--
--	activity gene server driver
--

-- env
local AnalyticsService = game:GetService("AnalyticsService")
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
local activityUtil = require(activity.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Roster management
local function addPlayerToRoster(activityInstance, player)
	local teamIndex = activityUtil.getPlayerTeamIndex(activityInstance, player)
	collection.addValue(activityInstance.state.activity.roster[teamIndex], player)
end
local function removePlayerFromRosters(player)
	genesUtil.getInstances(activity):foreach(function (activityInstance)
		local roster = activityInstance.state.activity.roster
		for _, folder in pairs(roster:GetChildren()) do
			collection.removeValue(folder, player)
		end
	end)
end

-- Handy self-explanatory stream utility functions
local function stopSession(activityInstance)
	local state = activityInstance.state.activity
	collection.clear(state.enrolledTeams)
	state.inSession.Value = false
	collection.clear(state.sessionTeams)
	for _, folder in pairs(state.roster:GetChildren()) do
		collection.clear(folder)
	end
end
local function clearWinner(activityInstance)
	activityInstance.state.activity.winningTeam.Value = nil
end

-- Start collecting roster
local function getRosterTimerLabel(activityInstance)
	local timerLabel = activityInstance:FindFirstChild("RosterTimerLabel", true)
	if not timerLabel then
		error("No RosterTimerLabel found in " .. activityInstance:GetFullName())
	end
	return timerLabel
end
local function setRosterTimerVisible(activityInstance, visible)
	local timerLabel = getRosterTimerLabel(activityInstance)
	timerLabel.Parent.Enabled = visible
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
	local timerLabel = getRosterTimerLabel(activityInstance)
	local function setTimerText(t)
		timerLabel.Text = t
	end
	rx.Observable.heartbeat()
		:scan(function (t, dt)
			return t - dt
		end, activityInstance.config.activity.rosterCollectionTimer.Value)
		:map(math.floor)
		:takeUntil(rx.Observable.from(state.isCollectingRoster):reject())
		:subscribe(setTimerText)

	-- Create roster folders
	for i = 1, activityInstance.config.activity.teamCount.Value do
		Instance.new("Folder", state.roster).Name = i
	end

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

-- Start PLAY
local function startPlay(activityInstance)
	-- Get state
	local state = activityInstance.state.activity
	print("starting play")

	-- If we have players on both teams, then start a match
	local hasBoth = true
	for _, folder in pairs(state.roster:GetChildren()) do
		if #folder:GetChildren() == 0 then
			hasBoth = false
			break
		end
	end
	if not hasBoth then
		stopSession(activityInstance)
	end

	-- Either way, we are no longer collecting roster
	wait()
	state.isCollectingRoster.Value = false
end

-- Create trophy for activity instance and team, place it at the spawn
local function createTrophy(activityInstance, team)
	-- Create trophy
	local trophy = activityInstance.config.activity.trophy.Value:Clone()
	trophy:SetPrimaryPartCFrame(activityInstance.functional.TrophySpawn.CFrame)
	trophy.Parent = workspace

	-- Set decal part texture id
	trophy.DecalPart.Decal.Texture = team.config.team.image.Value

	-- Tag and apply functionality
	genesUtil.addGeneTag(trophy, genes.pickup)
	genesUtil.addGeneTag(trophy, genes.multiswitch.teamOnly)

	-- Play sound inside the trophy
	soundUtil.playSound(env.res.audio.sounds.MatchWon, trophy)

	-- Wait for full state
	genesUtil.waitForState(trophy, genes.multiswitch.teamOnly)
	trophy.config.teamOnly.team.Value = team
end

-- Render gates
local function setGatePartVisible(part, visible)
	part.CanCollide = visible
end
local function initGates(activityInstance)
	tableau.from(activityInstance:GetDescendants())
		:filter(function (m)
			return m.Name == "GateOpen" or m.Name == "GateClosed"
		end)
		:foreach(dart.bind(fx.new, "TransparencyEffect"))
end
local function renderGates(activityInstance)
	local inSession = activityInstance.state.activity.inSession.Value
	local function work(modelName, visible)
		local models = tableau.from(activityInstance:GetDescendants())
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

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local activities = genesUtil.initGene(activity)

-- Set roster timer visible
genesUtil.observeStateValue(activity, "isCollectingRoster"):subscribe(setRosterTimerVisible)

-- Listen to enrolled list changed and begin activity when it's full
-- We have to spawn the subscription to this because it is subscribes to the collection's ChildRemoved event
-- 	and will create an infinite loop if single-threaded
local rosterCollectingStart = activities
	:flatMap(function (activityInstance)
		local enrolled = activityInstance.state.activity.enrolledTeams
		return collection.observeChanged(enrolled)
			:reject(dart.bind(activityUtil.isInSession, activityInstance))
			:map(function () return #enrolled:GetChildren() end)
			:filter(dart.equals(activityInstance.config.activity.teamCount.Value))
			:map(dart.constant(activityInstance))
	end)
	:share()
rosterCollectingStart
	:map(dart.carry(startCollectingRoster))
	:map(dart.bind)
	:subscribe(spawn)
rosterCollectingStart:delay(function (activityInstance)
	return activityInstance.config.activity.rosterCollectionTimer.Value
end):subscribe(startPlay)

-- Add players to roster upon request
rx.Observable.from(activity.net.RosterJoinRequested)
	:filter(function (player, activityInstance)
		local state = activityInstance.state.activity
		return state.isCollectingRoster.Value and collection.getValue(state.sessionTeams, player.Team)
	end)
	:reject(activityUtil.isPlayerInAnyRoster)
	:map(function (p, a) return a, p end)
	:subscribe(addPlayerToRoster)

-- Remove players from roster when they leave the game or die
axisUtil.getPlayerCharacterStream():flatMap(function (_, character)
	return rx.Observable.from(character:WaitForChild("Humanoid").Died)
end):merge(rx.Observable.from(Players.PlayerRemoving))
	:subscribe(removePlayerFromRosters)

-- Stop session when a winner is declared from the inside
local winnerDeclared = genesUtil.observeStateValue(activity, "winningTeam")
	:filter(dart.select(2))

-- Create trophy when a winner is declared
winnerDeclared:subscribe(createTrophy)
winnerDeclared:map(dart.select(1)):subscribe(stopSession)

-- Clear winner after a moment
winnerDeclared
	:map(dart.carry(clearWinner))
	:map(dart.bind)
	:subscribe(spawn)

-- Hard switch gates on activity session
activities:subscribe(initGates)
genesUtil.observeStateValue(activity, "inSession")
	:subscribe(renderGates)
