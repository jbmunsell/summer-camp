--
--	Jackson Munsell
--	12 Nov 2020
--	activityEnrollment.client.lua
--
--	activityEnrollment gene client driver
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local activity = genes.activity
local activityEnrollment = activity.activityEnrollment

-- modules
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local glib = require(axis.lib.glib)
local tableau = require(axis.lib.tableau)
local collection = require(axis.lib.collection)
local dataUtil = require(env.src.data.util)
local genesUtil = require(genes.util)
local activityUtil = require(activity.util)

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local CounselorJoinText = "Join"
local CamperJoinText = "Ask your counselor to join."
local ReturnLaterText = "Come back later."

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Basic setters
local function setLeaveButtonVisible(enrollmentInstance, visible)
	enrollmentInstance:FindFirstChild("LeaveButton", true).Visible = visible
end
local function setJoinButtonVisible(enrollmentInstance, visible)
	enrollmentInstance:FindFirstChild("JoinButton", true).Visible = visible
end
local function setJoinButtonText(enrollmentInstance, text)
	enrollmentInstance:FindFirstChild("JoinButton", true).TextLabel.Text = text
end
local function setStatusText(enrollmentInstance, text)
	enrollmentInstance:FindFirstChild("StatusDisplay", true).TextLabel.Text = text
end
local function setTeamListVisible(enrollmentInstance, visible)
	enrollmentInstance:FindFirstChild("TeamList", true).Visible = visible
end

-- Get status text
local function getStatusText(activityInstance)
	if activityInstance.state.activity.inSession.Value then
		return (activityInstance.config.activity.teamCount.Value > 1 and "Match" or "Activity")
			.. " in progress."
	elseif activityUtil.isActivityChunk() then
		local enrolled = activityInstance.state.activity.enrolledTeams
		local desiredCount = activityInstance.config.activity.teamCount.Value
		return string.format("%d/%d Teams Ready", #enrolled:GetChildren(), desiredCount)
	else
		return ReturnLaterText
	end

end

-- Display teams
local function displayTeams(enrollmentInstance, folder)
	local teamList = enrollmentInstance:FindFirstChild("TeamList", true)
	local function createImage(team)
		local image = enrollmentInstance:FindFirstChild("seeds", true).TeamImage:Clone()
		image.Image = env.config.cabins[team.Name].image.Value
		image.Visible = true
		image.Parent = teamList
	end

	glib.clearLayoutContents(teamList)
	tableau.from(folder:GetChildren())
		:map(dart.index("Value"))
		:foreach(createImage)
end

---------------------------------------------------------------------------------------------------
-- Display streams
---------------------------------------------------------------------------------------------------

-- All enrollments
local enrollments = genesUtil.initGene(activityEnrollment)
	:flatMap(function (enrollmentInstance)
		return genesUtil.getInstanceStream(activity)
			:filter(function (activityInstance)
				return enrollmentInstance:IsDescendantOf(activityInstance)
			end)
			:first()
			:map(dart.carry(enrollmentInstance))
	end)

-- Activity chunk stream
local isActivityChunkStream = activityUtil.isActivityChunkStream

-- Is local player counselor
dataUtil.waitForState(env.LocalPlayer, "roles")
local isCounselor = rx.Observable.from(env.LocalPlayer.state.roles.isCounselor)

-- Get a stream from an activity's inSession value
local function getSessionStream(activityInstance)
	return rx.Observable.from(activityInstance.state.activity.inSession)
end
local function getEnrolledTeamsStream(activityInstance)
	return collection.observeChanged(activityInstance.state.activity.enrolledTeams)
end

-- Get a stream that will fire with whether or not the local player's team is enrolled
-- 	in a specific activity instance
local function getLocalTeamEnrolledStream(activityInstance)
	local enrolledTeams = activityInstance.state.activity.enrolledTeams
	local enrolledStream = getEnrolledTeamsStream(activityInstance)
	return rx.Observable.fromProperty(env.LocalPlayer, "Team")
		:startWith(env.LocalPlayer.Team)
		:combineLatest(enrolledStream:startWith(0), function ()
			return collection.getValue(enrolledTeams, env.LocalPlayer.Team)
		end)
		:map(dart.boolify)
end

-- Leave button should be shown when this player is a counselor
-- 	AND this player's team is enrolled in the activity
enrollments:flatMap(function (enrollmentInstance, activityInstance)
	return isCounselor:combineLatest(getLocalTeamEnrolledStream(activityInstance), dart.boolAnd)
		:map(dart.carry(enrollmentInstance))
end):subscribe(setLeaveButtonVisible)

-- Join button should be shown when it's an activity chunk
-- 	AND we are not already enrolled
-- 	AND this activity is not in session
enrollments:flatMap(function (enrollmentInstance, activityInstance)
	local noSession = getSessionStream(activityInstance):map(dart.boolNot)
	local notEnrolled = getLocalTeamEnrolledStream(activityInstance):map(dart.boolNot)
	return isActivityChunkStream:combineLatest(noSession, notEnrolled, dart.boolAll)
		:map(dart.carry(enrollmentInstance))
end):subscribe(setJoinButtonVisible)

-- Join button text should be "Join" if counselor and "Ask your counselor to sign up!"
-- 	if not a counselor
enrollments:flatMap(function (enrollmentInstance, _)
	return isCounselor
		:map(function (c) return c and CounselorJoinText or CamperJoinText end)
		:map(dart.carry(enrollmentInstance))
end):subscribe(setJoinButtonText)

-- Status text should be "Match in progress" if inSession
-- 	else "x/x Teams Ready" if activity chunk
-- 	else "Come back later" if not activity chunk
enrollments:flatMap(function (enrollmentInstance, activityInstance)
	local isInSession = getSessionStream(activityInstance)
	local enrolledStream = getEnrolledTeamsStream(activityInstance):startWith(0)
	return isInSession:combineLatest(isActivityChunkStream, enrolledStream,
		dart.bind(getStatusText, activityInstance))
		:map(dart.carry(enrollmentInstance))
end):subscribe(setStatusText)

-- Team list should show sessionTeams if inSession
-- 	and enrolledTeams if not inSession
local function streamFromFolder(folder)
	return collection.observeChanged(folder)
		:startWith(0)
		:map(dart.constant(folder))
end
enrollments:flatMap(function (enrollmentInstance, activityInstance)
	return getSessionStream(activityInstance):switchMap(function (inSession)
		local state = activityInstance.state.activity
		return inSession
			and streamFromFolder(state.sessionTeams)
			or streamFromFolder(state.enrolledTeams)
	end):map(dart.carry(enrollmentInstance))
end):subscribe(displayTeams)

-- Team list visible should be (is activity chunk)
enrollments:flatMap(function (enrollmentInstance, _)
	return isActivityChunkStream:map(dart.carry(enrollmentInstance))
end):subscribe(setTeamListVisible)

---------------------------------------------------------------------------------------------------
-- Input streams
---------------------------------------------------------------------------------------------------

-- Fire when a user clicks join or leave
local function forwardButton(buttonName, remote)
	enrollments:flatMap(function (enrollmentInstance)
		return rx.Observable.from(enrollmentInstance:FindFirstChild(buttonName, true).Activated)
			:map(dart.constant(enrollmentInstance))
	end):subscribe(dart.forward(remote))
end
forwardButton("JoinButton", activityEnrollment.net.JoinRequested)
forwardButton("LeaveButton", activityEnrollment.net.LeaveRequested)
