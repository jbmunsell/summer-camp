--
--	Jackson Munsell
--	09 Nov 2020
--	activityEnrollment.server.lua
--
--	activity.activityEnrollment gene server driver
--

-- env
local TweenService = game:GetService("TweenService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local genes = env.src.genes
local activity = genes.activity
local activityEnrollment = activity.activityEnrollment

-- modules
local fx = require(axis.lib.fx)
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local genesUtil = require(genes.util)
local interactUtil = require(genes.interact.util)
local multiswitchUtil = require(genes.multiswitch.util)
local rolesUtil = require(env.src.roles.util)
local activityUtil = require(activity.util)
local activityEnrollmentData = require(activityEnrollment.data)

---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

-- Render visible
local function renderVisible(instance)
	local info = activityEnrollmentData.transparencyTweenInfo
	local visible = instance.state.activityEnrollment.visible.Value
	TweenService:Create(instance.TransparencyEffect, info, { Value = (visible and 0 or 1) }):Play()
end

---------------------------------------------------------------------------------------------------
-- Streams
---------------------------------------------------------------------------------------------------

-- init
local enrollments = genesUtil.initGene(activityEnrollment)

-- Create transparency effects
enrollments:subscribe(dart.bind(fx.new, "TransparencyEffect"))

-- Pass player triggering from interact
interactUtil.getInteractStream(activityEnrollment)
	:filter(rolesUtil.isPlayerCounselor)
	:subscribe(function (player, instance)
		instance.interface.activityEnrollment.cabinCounselorTriggered:Fire(player.Team)
	end)

-- Bind visibility to activity is NOT in session and schedule chunk is activity
enrollments
	:flatMap(function (enrollmentInstance)
		return genesUtil.getInstanceStream(activity)
			:filter(function (activityInstance) return enrollmentInstance:IsDescendantOf(activityInstance) end)
			:flatMap(function (activityInstance)
				return rx.Observable.from(activityInstance.state.activity.inSession)
					:map(dart.boolNot)
					:combineLatest(activityUtil.isActivityChunkStream, dart.boolAnd)
					:map(dart.carry(enrollmentInstance))
			end)
	end)
	:subscribe(genesUtil.setStateValue(activityEnrollment, "visible"))

-- Render visibile
local visibleStream = genesUtil.observeStateValue(activityEnrollment, "visible")
visibleStream
	:map(function (instance, visible)
		return instance, "interact", "activityEnrollment", visible
	end)
	:subscribe(multiswitchUtil.setSwitchEnabled)
visibleStream:subscribe(renderVisible)
