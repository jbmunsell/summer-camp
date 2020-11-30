--
--	Jackson Munsell
--	09 Nov 2020
--	activity.util.lua
--
--	activity gene util
--

-- env
local Players = game:GetService("Players")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local activity = genes.activity

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local tableau = require(axis.lib.tableau)
local axisUtil = require(axis.lib.axisUtil)
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)
local scheduleStreams = require(env.src.schedule.streams)
local pickupUtil = require(genes.pickup.util)

-- lib
local activityUtil = {}

-- Is in session
function activityUtil.isInSession(activityInstance)
	return activityInstance.state.activity.inSession.Value
end
function activityUtil.isInPlay(activityInstance)
	local state = activityInstance.state.activity
	return state.inSession.Value
	and not state.isCollectingRoster.Value
end

-- Current chunk is activity chunk
function activityUtil.isActivityChunk()
	local chunk = scheduleStreams.scheduleChunk:getValue()
	return chunk and chunk.Name == "OpenActivityChunk"
end
activityUtil.isActivityChunkStream = scheduleStreams.scheduleChunk
	:map(activityUtil.isActivityChunk)

-- Get cabin activity
function activityUtil.getTeamActivity(team)
	return genesUtil.getInstances(activity)
		:first(function (activityInstance)
			return collection.getValue(activityInstance.state.activity.sessionTeams, team)
		end)
end

-- Get team index
function activityUtil.getTeamIndex(activityInstance, team)
	local value = collection.getValue(activityInstance.state.activity.sessionTeams, team)
	return value and tonumber(value.Name)
end

-- is player competing
function activityUtil.getPlayerActivity(player)
	return genesUtil.getInstances(activity):first(function (activityInstance)
		return activityUtil.isPlayerInRoster(activityInstance, player)
	end)
end
function activityUtil.isPlayerCompeting(player)
	return activityUtil.getPlayerActivity(player) and true or nil
end

-- Remove player from roster
function activityUtil.removePlayerFromRosters(player)
	local function pluck(roster)
		for _, folder in pairs(roster:GetChildren()) do
			collection.removeValue(folder, player)
		end
	end
	genesUtil.getInstances(activity):foreach(function (activityInstance)
		local state = activityInstance.state.activity
		pluck(state.fullRoster)
		pluck(state.roster)
	end)
end

-- Get player competing stream
function activityUtil.getPlayerCompetingStream(player)
	return genesUtil.getInstanceStream(activity):flatMap(function (activityInstance)
		local roster = activityInstance.state.activity.roster
		local function isPlayer(o)
			return o:filter(dart.isa("ObjectValue"))
					:filter(function (c) return c.Value == player end)
		end
		return rx.Observable.from(roster.DescendantAdded)
			:startWithTable(roster:GetDescendants())
			:pipe(isPlayer)
			:map(dart.constant(true))
			:merge(rx.Observable.from(roster.DescendantRemoving)
				:pipe(isPlayer)
				:map(dart.constant(false)))
	end):takeUntil(rx.Observable.from(Players.PlayerRemoving):filter(dart.equals(player)))
end
function activityUtil.getPlayerActivityStream(player)
	return genesUtil.getInstanceStream(activity):flatMap(function (activityInstance)
		local roster = activityInstance.state.activity.roster
		local function isPlayer(o)
			return o:filter(dart.isa("ObjectValue"))
					:filter(function (c) return c.Value == player end)
		end
		return rx.Observable.from(roster.DescendantAdded)
			:startWithTable(roster:GetDescendants())
			:pipe(isPlayer)
			:map(dart.constant(activityInstance))
			:merge(rx.Observable.from(roster.DescendantRemoving)
				:pipe(isPlayer)
				:map(dart.constant(nil)))
	end):takeUntil(rx.Observable.from(Players.PlayerRemoving):filter(dart.equals(player)))
end

-- Get player added to roster stream
local function getPlayerRosterValue(roster, player)
	for _, folder in pairs(roster:GetChildren()) do
		if collection.getValue(folder, player) then
			return true
		end
	end
	return false
end
function activityUtil.getPlayerTeamIndex(activityInstance, player)
	local value = collection.getValue(activityInstance.state.activity.sessionTeams, player.Team)
	return value and tonumber(value.Name)
end
function activityUtil.isPlayerInRoster(activityInstance, player)
	return getPlayerRosterValue(activityInstance.state.activity.roster, player)
end
function activityUtil.isPlayerInFullRoster(activityInstance, player)
	return getPlayerRosterValue(activityInstance.state.activity.fullRoster, player)
end
function activityUtil.getPlayerAddedToRosterStream(gene)
	return genesUtil.getInstanceStream(gene):flatMap(function (activityInstance)
		return rx.Observable.from(activityInstance.state.activity.roster.DescendantAdded)
			:filter(dart.isa("ObjectValue"))
			:map(dart.index("Value"))
			:filter()
			:map(dart.carry(activityInstance))
	end)
end
function activityUtil.getPlayerRemovedFromRosterStream(gene)
	return genesUtil.getInstanceStream(gene):flatMap(function (activityInstance)
		local roster = activityInstance.state.activity.roster
		return rx.Observable.from(roster.ChildAdded):startWithTable(roster:GetChildren())
			:flatMap(function (teamFolder)
				return rx.Observable.from(teamFolder.ChildRemoved)
			end)
			:map(dart.index("Value"))
			:map(dart.carry(activityInstance))
	end)
end
function activityUtil.getSingleTeamLeftStream(gene)
	return activityUtil.getPlayerRemovedFromRosterStream(gene)
		:filter(activityUtil.isInPlay)
		:reject(function (activityInstance)
			return activityInstance.state.activity.winningTeam.Value
		end)
		:map(function (instance)
			for i = 1, 2 do
				if #instance.state.activity.roster[i]:GetChildren() == 0 then
					return instance, instance.state.activity.sessionTeams[3 - i].Value
				end
			end
		end)
		:filter()
end

-- Team roster streams
function activityUtil.getTeamRoster(activityInstance, team)
	local index = activityUtil.getTeamIndex(activityInstance, team)
	return activityInstance.state.activity.roster[index]
end
function activityUtil.getTeamFullRoster(activityInstance, team)
	local index = activityUtil.getTeamIndex(activityInstance, team)
	return activityInstance.state.activity.fullRoster[index]
end
function activityUtil.getTeamRosterChangedStream(activityInstance, team, init)
	return collection.observeChanged(activityUtil.getTeamRoster(activityInstance, team), init)
end
function activityUtil.isTeamRosterFull(activityInstance, team)
	local maxPlayers = activityInstance.config.activity.maxPlayersPerTeam.Value
	return #activityUtil.getTeamRoster(activityInstance, team):GetChildren() == maxPlayers
end

-- Declare winner
function activityUtil.declareWinner(activityInstance, team)
	activityInstance.state.activity.winningTeam.Value = team
end

-- Stop a session
function activityUtil.stopSession(activityInstance)
	local state = activityInstance.state.activity
	collection.clear(state.enrolledTeams)
	state.inSession.Value = false
	state.winningTeam.Value = nil
	collection.clear(state.sessionTeams)
	for _, folder in pairs(state.roster:GetChildren()) do
		collection.clear(folder)
	end
	for _, folder in pairs(state.fullRoster:GetChildren()) do
		collection.clear(folder)
	end
	for _, value in pairs(state.score:GetChildren()) do
		value.Value = 0
	end
end

-- Zero join terminate
function activityUtil.zeroJoinTerminate(activityInstance)
	for _, folder in pairs(activityInstance.state.activity.roster:GetChildren()) do
		for _, value in pairs(folder:GetChildren()) do
			activity.net.ZeroJoinCase:FireClient(value.Value)
		end
	end
	activityUtil.stopSession(activityInstance)
end

-- Spawn players in plane
function activityUtil.spawnPlayersInPlane(players, plane, lookAtPosition)
	local function place(character)
		local point = axisUtil.getRandomPointInPart(plane)
		local cf = character:GetPrimaryPartCFrame()
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Sit = false
			wait()
		end
		local cframe = CFrame.new(point, lookAtPosition or point + cf.LookVector)
		pickupUtil.teleportCharacterWithHeldObjects(character, cframe)
	end

	tableau.from(players)
		:map(dart.index("Character"))
		:filter()
		:foreach(place)
end
function activityUtil.spawnPlayer(activityInstance, player)
	local teamIndex = activityUtil.getTeamIndex(activityInstance, player.Team)
	if teamIndex then
		local plane = activityInstance.functional["Team" .. teamIndex .. "SpawnPlane"]
		activityUtil.spawnPlayersInPlane({ player }, plane)
	end
end

-- Eject players from instance
function activityUtil.ejectPlayerFromActivity(activityInstance, player)
	local ejectionSpawnPlane = activityInstance:FindFirstChild("EjectionSpawnPlane", true)
	if not ejectionSpawnPlane then return end
	activityUtil.spawnPlayersInPlane({ player }, ejectionSpawnPlane)
end
function activityUtil.ejectPlayers(activityInstance)
	local pitchBounds = activityInstance:FindFirstChild("PitchBounds", true)
	assert(pitchBounds, activityInstance:GetFullName() .. " does not have pitch bounds.")

	for _, player in pairs(Players:GetPlayers()) do
		local root = axisUtil.getPlayerHumanoidRootPart(player)
		if root and axisUtil.isPointInPartXZ(root.Position, pitchBounds) then
			activityUtil.ejectPlayerFromActivity(activityInstance, player)
		end
	end
end

-- return lib
return activityUtil
