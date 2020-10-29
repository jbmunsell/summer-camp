--
--	Jackson Munsell
--	23 Aug 2020
--	EngagementPortal.lua
--
--	Activity engagement portal component
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)

-- modules
local axisUtil = require(env.axis.lib.axisUtil)
local class = require(env.axis.lib.class)
local dart = require(env.axis.lib.dart)
local rx = require(env.axis.lib.rx)
local fx = require(env.axis.lib.fx)
local InstanceTags = require(env.src.shared.enum.InstanceTags)

-- class
local EngagementPortal = class.new()

-- Object maintenance
function EngagementPortal.init(self, activityInstance)
	-- Hold activity instance
	self.activityInstance = activityInstance

	-- Create and place portal
	local point = axisUtil.getFirstTaggedDescendant(activityInstance, InstanceTags.EngagementPoint)
	self.instance = env.res.activities.models.EngagementPortal:Clone()
	fx.placeModelOnGroundAtPoint(self.instance, point.Position)
	self.instance.Parent = env.ReplicatedStorage

	-- Create streams
	local touchedByCabinLeader = rx.Observable.from(self.instance.PrimaryPart.Touched)
		:map(dart.getPlayerFromCharacterChild)
		:filter(function (player)
			return player and player.state.isCabinLeader.Value
		end)
		:throttleFirst(1.0)
	self.streams = {
		touchedByCabinLeader = touchedByCabinLeader,
	}
end
function EngagementPortal.destroy(self)
	-- Nothing to do here
end

-- Set active
function EngagementPortal.setActive(self, active)
	self.instance.Parent = (active and self.activityInstance or env.ReplicatedStorage)
end

-- Set activity name
function EngagementPortal.setActivityName(self, activityName)
	rx.Observable.from(self.instance:GetDescendants())
		:filter(dart.isa("TextLabel"))
		:subscribe(function (label)
			label.Text = string.format("Start %s", activityName)
		end)
end

-- return class
return EngagementPortal
