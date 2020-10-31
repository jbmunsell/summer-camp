--
--	Jackson Munsell
--	04 Sep 2020
--	axisUtil.lua
--
--	Collection of handy functions that don't really belong in any other specific place
--

-- env
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- lib
local axisUtil = {}

-- Constants
local SmoothAttachTweenInfo = TweenInfo.new(
	0.3,
	Enum.EasingStyle.Cubic,
	Enum.EasingDirection.Out
)
local ImpulseDuration = 0.1
local ImpulseProperties = {
	VectorForce = "Force",
	Torque      = "Torque",
}

-- Utility functions
local function jip()
	return math.random() - 0.5
end

-- Destroy child by name if it exists
function axisUtil.destroyChild(instance, childName)
	local child = instance:FindFirstChild(childName)
	if child then
		child:Destroy()
	end
end

-- Get player humanoid
function axisUtil.getPlayerHumanoid(player)
	return player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
end
function axisUtil.getPlayerHumanoidRootPart(player)
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

-- Get local humanoid
function axisUtil.getLocalHumanoid()
	if not RunService:IsClient() then
		error("axisUtil.getLocalHumanoid can only be called from the client.")
	end
	local player = Players.LocalPlayer
	local character = player and player.Character
	return character and character:FindFirstChildWhichIsA("Humanoid")
end
function axisUtil.getLocalHumanoidRootPart()
	if not RunService:IsClient() then
		error("axisUtil.getLocalHumanoidRootPart can only be called from the client.")
	end
	local player = Players.LocalPlayer
	local character = player and player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

-- Set properties
function axisUtil.setProperties(instance, properties)
	for k, v in pairs(properties) do
		instance[k] = v
	end
end

-- Get tagged ancestor
function axisUtil.getTaggedAncestor(instance, tag)
	while instance and instance ~= game do
		instance = instance.Parent
		if CollectionService:HasTag(instance, tag) then
			return instance
		end
	end
	return nil
end

-- Get descendants with a specific collection service tag
function axisUtil.getTaggedDescendants(instance, tag)
	local tagged = {}
	for _, v in pairs(CollectionService:GetTagged(tag)) do
		if v:IsDescendantOf(instance) then
			table.insert(tagged, v)
		end
	end
	return tagged
end
function axisUtil.getFirstTaggedDescendant(instance, tag)
	return axisUtil.getTaggedDescendants(instance, tag)[1]
end

-- Get random point inside of a part
function axisUtil.getRandomPointInPart(part)
	return (part.CFrame * CFrame.new(jip() * part.Size.X, jip() * part.Size.Y, jip() * part.Size.Z)).p
end
function axisUtil.getRandomPointInPartXZ(part)
	return (part.CFrame * CFrame.new(jip() * part.Size.X, 0, jip() * part.Size.Z)).p
end

-- Is point inside of part
-- Very naive
function axisUtil.isPointInPart(point, part)
	local a = part.CFrame * CFrame.new(-part.Size * 0.5)
	local b = a * CFrame.new(part.Size)
	a, b = a.p, b.p
	
	return	point.X >= math.min(a.X, b.X) and point.X <= math.max(a.X, b.X)
	and		point.Y >= math.min(a.Y, b.Y) and point.Y <= math.max(a.Y, b.Y)
	and		point.Z >= math.min(a.Z, b.Z) and point.Z <= math.max(a.Z, b.Z)
end
function axisUtil.isPointInPartXZ(point, part)
	local a = part.CFrame * CFrame.new(-part.Size * 0.5)
	local b = a * CFrame.new(part.Size)
	a, b = a.p, b.p
	
	return	point.X >= math.min(a.X, b.X) and point.X <= math.max(a.X, b.X)
	and		point.Z >= math.min(a.Z, b.Z) and point.Z <= math.max(a.Z, b.Z)
end

-- Calculate mass of a whole model
function axisUtil.getModelMass(model)
	local mass = 0
	for _, child in pairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			mass = mass + child:GetMass()
		end
	end
	return mass
end

-- Base apply impulse function
local function applyCharacterImpulse(character, impulse, instanceType)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		print("Cannot apply velocity impulse to character with no root part")
		return
	end

	local impulseProperty = ImpulseProperties[instanceType]
	local impulseObject = Instance.new(instanceType, root)
	impulseObject.RelativeTo = Enum.ActuatorRelativeTo.World
	impulseObject.Attachment0 = root.RootRigAttachment
	impulseObject[impulseProperty] = axisUtil.getModelMass(character) * impulse
	delay(ImpulseDuration, function ()
		impulseObject:Destroy()
	end)
end

-- Apply a velocity impulse to a character
function axisUtil.applyCharacterVelocityImpulse(character, impulse)
	applyCharacterImpulse(character, impulse, "VectorForce")
end

-- Apply a rotation impulse to a character via torque
-- NOTE: This only works with characters that are in a physics based state
function axisUtil.applyCharacterRotationImpulse(character, impulse)
	applyCharacterImpulse(character, impulse, "Torque")
end

-- Create dynamic tween
function axisUtil.createDynamicTween(instance, tweenInfo, targets)
	-- Create proxy value object
	local val = Instance.new("NumberValue", ReplicatedStorage)
	val.Value = 0
	local pulse = RunService.Heartbeat:Connect(function ()
		for property, getTarget in pairs(targets) do
			instance[property] = getTarget(val.Value)
		end
	end)
	local tween = TweenService:Create(val, tweenInfo, { Value = 1 })
	tween.Completed:Connect(function () pulse:Disconnect() end)
	return tween
end

-- Weld attachment and tween
function axisUtil.getObjectCFrame(object)
	if object:IsA("BasePart") then
		return object.CFrame
	elseif object:IsA("Model") then
		return object:GetPrimaryPartCFrame()
	end
end
function axisUtil.computeAttachInfo(a, b, attachmentName)
	-- Get attachments
	local att_a = a:FindFirstChild(attachmentName, true)
	local att_b = b:FindFirstChild(attachmentName, true)
	assert(att_a and att_b, "Unable to find attachments for name '" .. attachmentName .. "'; "
		.. a:GetFullName() .. " and " .. b:GetFullName())

	local target = att_a.CFrame * att_b.CFrame:inverse()
	local current = att_a.Parent.CFrame:toObjectSpace(att_b.Parent.CFrame)

	return {
		att_a = att_a,
		att_b = att_b,
		target = target,
		current = current,
	}
end

-- This function will simply align the parents of two attachments, moving B to match A's CFrame.
-- 	It does not create a weld.
function axisUtil.snapAttachments(att_a, att_b)
	att_b.Parent.CFrame = att_a.WorldCFrame:toWorldSpace(att_b.CFrame:inverse())
end

-- This function will align the parents of two attachments so that B matches A's CFrame,
-- 	doing so using a weld.
function axisUtil.snapAttach(a, b, attachmentName)
	local info = axisUtil.computeAttachInfo(a, b, attachmentName)
	local weld = Instance.new("Weld")
	weld.Part0 = info.att_a.Parent
	weld.Part1 = info.att_b.Parent
	weld.C0 = info.target
	weld.Parent = a

	return weld
end
function axisUtil.smoothAttach(a, b, attachmentName, tweenInfo)
	local info = axisUtil.computeAttachInfo(a, b, attachmentName)
	local originalCFrame = info.att_b.Parent.CFrame
	local function getTargetCFrame()
		return info.att_a.WorldCFrame:toWorldSpace(info.att_b.CFrame:inverse())
	end

	local wasAnchored = info.att_b.Parent.Anchored
	info.att_b.Parent.Anchored = true

	local weld = Instance.new("Weld")
	weld.C0 = info.target

	local collisionGroups = {}
	local instances = (b:IsA("BasePart") and { b } or b:GetDescendants())
	for _, d in pairs(instances) do
		if d:IsA("BasePart") then
			collisionGroups[d] = d.CollisionGroupId
			PhysicsService:SetPartCollisionGroup(d, "FXParts")
		end
	end
	local tween = axisUtil.createDynamicTween(info.att_b.Parent, tweenInfo or SmoothAttachTweenInfo, {
		CFrame = function (d)
			return originalCFrame:lerp(getTargetCFrame(), d)
		end,
	})
	tween.Completed:Connect(function ()
		info.att_b.Parent.Anchored = wasAnchored

		for part, group in pairs(collisionGroups) do
			part.CollisionGroupId = group
		end

		weld.Part0 = info.att_a.Parent
		weld.Part1 = info.att_b.Parent
		if not weld.Parent then
			weld.Parent = a
		end
	end)
	tween:Play()

	return weld, tween, info
end

-- return lib
return axisUtil
