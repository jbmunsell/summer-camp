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
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)
local scheduleStreams = require(env.src.schedule.streams)

-- lib
local activityUtil = {}

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

-- return lib
return activityUtil
