--
--	Jackson Munsell
--	09 Nov 2020
--	activityEnrollment.server.lua
--
--	activity.activityEnrollment gene server driver
--

-- env
local AnalyticsService = game:GetService("AnalyticsService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local activity = genes.activity
local activityEnrollment = activity.activityEnrollment

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local collection = require(axis.lib.collection)
local genesUtil = require(genes.util)
local counselorUtil = require(genes.player.counselor.util)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Join enrollment
local function joinActivityEnrollment(player, activityInstance)
	local enrolled = activityInstance.state.activity.enrolledTeams
	if not collection.getValue(enrolled, player.Team) then
		collection.addValue(enrolled, player.Team)
	end
	AnalyticsService:FireEvent("activityEnrollmentJoined", {
		playerId = player.UserId,
		team = player.Team.Name,
		activityName = activityInstance.config.activity.analyticsName.Value,
	})
end

-- Leave enrollment
local function leaveActivityEnrollment(player, activityInstance)
	collection.removeValue(activityInstance.state.activity.enrolledTeams, player.Team)
	AnalyticsService:FireEvent("activityEnrollmentLeft", {
		playerId = player.UserId,
		team = player.Team.Name,
		activityName = activityInstance.config.activity.analyticsName.Value,
	})
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
genesUtil.initGene(activityEnrollment)

-- Process requests from counselors
local function processCounselorRequest(remote, callback)
	rx.Observable.from(remote)
		:filter(counselorUtil.isCounselor)
		:flatMap(function (player, enrollmentInstance)
			return genesUtil.getInstanceStream(activity)
				:filter(function (activityInstance)
					return enrollmentInstance:IsDescendantOf(activityInstance)
				end)
				:first()
				:map(dart.carry(player))
		end)
		:subscribe(callback)
end
processCounselorRequest(activityEnrollment.net.JoinRequested, joinActivityEnrollment)
processCounselorRequest(activityEnrollment.net.LeaveRequested, leaveActivityEnrollment)
