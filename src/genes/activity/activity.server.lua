--
--	Jackson Munsell
--	09 Nov 2020
--	activity.server.lua
--
--	activity gene server driver
--

-- env
local AnalyticsService = game:GetService("AnalyticsService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local activity = genes.activity
-- local activityEnrollment = genes.activity.activityEnrollment

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)
local activityUtil = require(activity.util)
local scheduleStreams = require(env.src.schedule.streams)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Handy self-explanatory stream utility functions
local function isInSession(activityInstance)
	return activityInstance.state.activity.inSession.Value
end
-- local function isEnrolled(activityInstance, cabin)
-- 	return collection.getValue(activityInstance.state.activity.enrolledTeams, cabin)
-- end
-- local function enrollCabin(activityInstance, cabin)
-- 	collection.addValue(activityInstance.state.activity.enrolledTeams, cabin)
-- end
local function startSession(activityInstance)
	for _, value in pairs(activityInstance.state.activity.enrolledTeams:GetChildren()) do
		value.Parent = activityInstance.state.activity.sessionTeams
	end

	-- Set state value to trigger action
	activityInstance.state.activity.inSession.Value = true

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
local function stopSession(activityInstance)
	collection.clear(activityInstance.state.activity.enrolledTeams)
	activityInstance.state.activity.inSession.Value = false
end
local function clearWinner(activityInstance)
	activityInstance.state.activity.winningTeam.Value = nil
end

-- Create trophy for activity instance and team, place it at the spawn
local function createTrophy(activityInstance, cabin)
	-- Create trophy
	local trophy = activityInstance.config.activity.trophy.Value:Clone()
	trophy.CFrame = activityInstance.functional.TrophySpawn.CFrame
	trophy.Parent = workspace

	-- Tag and apply functionality
	genesUtil.addGene(trophy, genes.pickup)
	genesUtil.addGene(trophy, genes.multiswitch.teamOnly)
	genesUtil.addGene(trophy, genes.multiswitch.counselorOnly)

	-- Wait for full state
	local function setTeam()
		trophy.config.teamOnly.team.Value = cabin
	end
	genesUtil.getInstanceStream(genes.multiswitch.teamOnly)
		:filter(dart.equals(trophy))
		:first()
		:subscribe(setTeam)
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init gene
local activities = genesUtil.initGene(activity)

-- Listen to activityEnrollment requests from child with gene
-- activities
-- 	:flatMap(function (activityInstance)
-- 		return genesUtil.getInstanceStream(activityEnrollment)
-- 			:filter(dart.isDescendantOf(activityInstance))
-- 			:flatMap(function (enrollmentInstance)
-- 				return rx.Observable.from(enrollmentInstance.interface.activityEnrollment.cabinCounselorTriggered)
-- 			end)
-- 			:reject(dart.bind(isEnrolled, activityInstance))
-- 			:reject(activityUtil.getCabinActivity)
-- 			:reject(dart.bind(isInSession, activityInstance))
-- 			:map(dart.carry(activityInstance))
-- 	end)
-- 	:subscribe(enrollCabin)

-- Listen to enrolled list changed and begin activity when it's full
-- We have to spawn the subscription to this because it is subscribes to the collection's ChildRemoved event
-- 	and will create an infinite loop if single-threaded
activities
	:flatMap(function (activityInstance)
		local enrolled = activityInstance.state.activity.enrolledTeams
		return collection.observeChanged(enrolled)
			:filter(activityUtil.isActivityChunk)
			:reject(dart.bind(isInSession, activityInstance))
			:map(function () return #enrolled:GetChildren() end)
			:filter(dart.equals(activityInstance.config.activity.teamCount.Value))
			:map(dart.constant(activityInstance))
	end)
	:map(dart.carry(startSession))
	:map(dart.bind)
	:subscribe(spawn)

-- Stop session when activity chunk ends OR when a winner is declared from the inside
local winnerDeclared = genesUtil.observeStateValue(activity, "winningTeam")
	:filter(dart.select(2))
scheduleStreams.scheduleChunk
	:reject(activityUtil.isActivityChunk)
	:map(dart.bind(genesUtil.getInstances, activity))
	:flatMap(rx.Observable.from)
	:merge(winnerDeclared:map(dart.select(1)))
	:subscribe(stopSession)

-- Create trophy when a winner is declared
winnerDeclared:subscribe(createTrophy)

-- Clear winner after a moment
winnerDeclared
	:map(dart.carry(clearWinner))
	:map(dart.bind)
	:subscribe(spawn)
