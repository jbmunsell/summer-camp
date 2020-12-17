--
--	Jackson Munsell
--	13 Sep 2020
--	ragdoll.client.lua
--
--	Ragdoll driver - inits ragdoll for local characters and listens to server ragdoll event
--

-- env
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local ragdoll = env.src.character.ragdoll

-- modules
require(env.packages.Ragdoll)
local rx = require(axis.lib.rx)
local dart = require(axis.lib.dart)
local axisUtil = require(axis.lib.axisUtil)
local ragdollConfig = require(ragdoll.config)

-- Variables
local ragdollCount = rx.BehaviorSubject.new(0)

-- Enable and disable ragdoll
local function setRagdollEnabled(humanoid, enabled)
	humanoid:ChangeState(enabled and Enum.HumanoidStateType.Physics or Enum.HumanoidStateType.GettingUp)
	humanoid.Parent.Animate.Disabled = enabled
	if enabled then
		for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
	end
end

-- Try dive
local function tryDive()
	-- Can't dive while dive
	local root = axisUtil.getLocalHumanoidRootPart()
	if ragdollCount:getValue() > 0 or not root then return end

	-- Can't dive while sitting
	local humanoid = axisUtil.getLocalHumanoid()
	if not humanoid or humanoid.Sit then return end

	-- Set ragdoll and launch player
	local horizontal, vertical = ragdollConfig.DiveHorizontalMagnitude, ragdollConfig.DiveVerticalMagnitude
	local trajectory = math.atan2(root.CFrame.lookVector.X, root.CFrame.lookVector.Z)
	local velocity = Vector3.new(math.sin(trajectory) * horizontal, vertical, math.cos(trajectory) * horizontal)
	local position = root.Position + ragdollConfig.DiveVerticalShift
	ragdollCount:push(ragdollCount:getValue() + 1)
	root.CFrame = CFrame.new(position, position + velocity) * ragdollConfig.DiveTwist
	root.Velocity = velocity
	delay(ragdollConfig.RagdollDuration, function ()
		ragdollCount:push(ragdollCount:getValue() - 1)
	end)
end

-- Create count changer
local function changeCount(delta)
	ragdollCount:push(math.max(0, ragdollCount:getValue() + delta))
end

-- Connect to ragdoll events
local function remoteToChange(remote, delta)
	return rx.Observable.from(remote):map(dart.constant(delta))
end
local pushStream = remoteToChange(ragdoll.net.Push, 1)
local popStream = remoteToChange(ragdoll.net.Pop, -1)
local resetStream = rx.Observable.from(env.LocalPlayer.CharacterAdded)
	:map(dart.constant(0))

-- Track ragdoll count
pushStream:merge(popStream)
	:subscribe(changeCount)
resetStream:multicast(ragdollCount)

-- Connect functions
ragdoll.interface.tryDive.OnInvoke = tryDive
ragdoll.interface.PushRagdoll.OnInvoke = dart.bind(changeCount, 1)
ragdoll.interface.PopRagdoll.OnInvoke = dart.bind(changeCount, -1)

-- Ragdoll according to count
ragdollCount
	:map(function (val)
		return (val > 0)
	end)
	:distinctUntilChanged()
	:map(function (enabled)
		return axisUtil.getLocalHumanoid(), enabled
	end)
	:filter()
	:subscribe(setRagdollEnabled)
