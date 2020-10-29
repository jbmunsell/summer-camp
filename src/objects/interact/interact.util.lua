--
--	Jackson Munsell
--	04 Sep 2020
--	interactUtil.lua
--
--	Interact util
--

-- env
local RunService = game:GetService("RunService")
local env = require(game:GetService("ReplicatedStorage").src.env)
local axis = env.packages.axis
local objects = env.src.objects
local interact = objects.interact

-- modules
local rx = require(axis.lib.rx)
local objectsUtil = require(objects.util)

-- lib
local interactUtil = {}

-- set interactable
function interactUtil.setInteractEnabled(instance, enabled)
	local valName = (RunService:IsServer() and "enabledServer" or "enabledClient")
	instance.state.interact[valName].Value = enabled
end

-- Create lock
function interactUtil.createLock(instance, lockName)
	Instance.new("BoolValue", instance.state.interact.locks).Name = lockName
	interactUtil.setLockEnabled(instance, lockName, false)
end

-- Set lock enabled
function interactUtil.setLockEnabled(instance, lockName, enabled)
	instance.state.interact.locks:WaitForChild(lockName).Value = enabled
end

-- Is locked
function interactUtil.isLocked(instance)
	for _, lock in pairs(instance.state.interact.locks:GetChildren()) do
		if lock.Value then return true end
	end
	return false
end

-- Get interact stream
function interactUtil.getInteractStream(class)
	if RunService:IsServer() then
		return rx.Observable.from(interact.net.ClientInteracted)
			:filter(function (_, instance)
				return objectsUtil.hasFullState(instance, class)
			end)
	elseif RunService:IsClient() then
		return rx.Observable.from(interact.interface.ClientInteracted)
			:filter(function (instance)
				return objectsUtil.hasFullState(instance, class)
			end)
	end
end

-- return lib
return interactUtil
