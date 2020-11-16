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
function activityUtil.getCabinActivity(team)
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
function activityUtil.isPlayerCompeting(player)
	return genesUtil.getInstances(activity):first(function (activityInstance)
		return activityUtil.isPlayerInRoster(activityInstance, player) and true or nil
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
	end)
end

-- Get player added to roster stream
function activityUtil.getPlayerTeamIndex(activityInstance, player)
	local value = collection.getValue(activityInstance.state.activity.sessionTeams, player.Team)
	return value and tonumber(value.Name)
end
function activityUtil.isPlayerInAnyRoster(player)
	return genesUtil.getInstances(activity):first(dart.follow(activityUtil.isPlayerInRoster, player))
end
function activityUtil.isPlayerInRoster(activityInstance, player)
	local roster = activityInstance.state.activity.roster
	for _, folder in pairs(roster:GetChildren()) do
		if collection.getValue(folder, player) then
			return true
		end
	end
	return false
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

-- Spawn players in plane
function activityUtil.spawnPlayersInPlane(players, plane, lookAtPosition)
	local function place(character)
		local point = axisUtil.getRandomPointInPart(plane)
		local cf = character:GetPrimaryPartCFrame()
		character:SetPrimaryPartCFrame(CFrame.new(point, lookAtPosition or point + cf.LookVector))
	end

	tableau.from(players)
		:map(dart.index("Character"))
		:filter()
		:foreach(place)
end

-- Eject players from instance
function activityUtil.ejectPlayers(activityInstance)
	local ejectionSpawnPlane = activityInstance:FindFirstChild("EjectionSpawnPlane", true)
	local pitchBounds = activityInstance:FindFirstChild("PitchBounds", true)
	assert(ejectionSpawnPlane and pitchBounds, activityInstance:GetFullName() .. " does not have ejection "
		.. "spawn plane or pitch bounds.")

	local players = tableau.from(Players:GetPlayers())
		:filter(function (p)
			local root = axisUtil.getPlayerHumanoidRootPart(p)
			return root and axisUtil.isPointInPartXZ(root.Position, pitchBounds)
		end)
	activityUtil.spawnPlayersInPlane(players:raw(), ejectionSpawnPlane)
end

-- return lib
return activityUtil
