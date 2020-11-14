--
--	Jackson Munsell
--	09 Nov 2020
--	activity.util.lua
--
--	activity gene util
--

-- env
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

-- Get player competing stream
function activityUtil.getPlayerCompetingStream(player)
	return genesUtil.getInstanceStream(activity)
		:flatMap(function (activityInstance)
			local teams = activityInstance.state.activity.sessionTeams
			return collection.observeChanged(teams)
		end)
		:merge(rx.Observable.fromProperty(player, "Team", true))
		:map(function ()
			return genesUtil.getInstances(activity):first(function (activityInstance)
				return collection.getValue(activityInstance.state.activity.sessionTeams, player.Team)
			end)
		end)
end

-- Spawn players in plane
function activityUtil.spawnPlayersInPlane(players, plane, lookAtPosition)
	local function place(character)
		character:SetPrimaryPartCFrame(CFrame.new(axisUtil.getRandomPointInPart(plane), lookAtPosition))
	end

	tableau.from(players)
		:map(dart.index("Character"))
		:filter()
		:foreach(place)
end

-- return lib
return activityUtil
